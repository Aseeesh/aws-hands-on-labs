#!/usr/bin/env bash
# Lab 06 - private S3 bucket + CloudFront distribution (Origin Access Control, HTTPS).
set -euo pipefail
REGION="${AWS_REGION:-ap-southeast-2}"
HERE="$(cd "$(dirname "$0")" && pwd)"
ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
BUCKET="lab-06-cdn-$(openssl rand -hex 3)"
ORIGIN="${BUCKET}.s3.${REGION}.amazonaws.com"

echo "== 1. Private bucket (Block Public Access stays ON) + site files"
aws s3api create-bucket --bucket "$BUCKET" --region "$REGION" --create-bucket-configuration LocationConstraint="$REGION" >/dev/null
aws s3api put-bucket-tagging --bucket "$BUCKET" --tagging 'TagSet=[{Key=Project,Value=aws-hands-on-labs},{Key=Lab,Value=06}]'
aws s3 sync "$HERE/../src" "s3://$BUCKET/" --delete --only-show-errors

echo "== 2. Origin Access Control (CloudFront signs its requests to S3)"
OAC=$(aws cloudfront create-origin-access-control --origin-access-control-config \
  "Name=lab-06-oac-${BUCKET##*-},Description=Lab 06,SigningProtocol=sigv4,SigningBehavior=always,OriginAccessControlOriginType=s3" \
  --query OriginAccessControl.Id --output text)

echo "== 3. CloudFront distribution (HTTPS only for viewers, cheapest price class)"
cat > /tmp/lab06-dist.json <<JSON
{
  "CallerReference": "lab-06-$(date +%s)",
  "Comment": "Lab 06 - aws-hands-on-labs",
  "Enabled": true,
  "PriceClass": "PriceClass_100",
  "DefaultRootObject": "index.html",
  "HttpVersion": "http2",
  "Origins": {"Quantity": 1, "Items": [{
    "Id": "s3-origin", "DomainName": "$ORIGIN", "OriginAccessControlId": "$OAC",
    "S3OriginConfig": {"OriginAccessIdentity": ""}}]},
  "DefaultCacheBehavior": {
    "TargetOriginId": "s3-origin",
    "ViewerProtocolPolicy": "redirect-to-https",
    "Compress": true,
    "AllowedMethods": {"Quantity": 2, "Items": ["GET","HEAD"], "CachedMethods": {"Quantity": 2, "Items": ["GET","HEAD"]}},
    "CachePolicyId": "658327ea-f89d-4fab-a63d-7e88639e58f6"
  },
  "CustomErrorResponses": {"Quantity": 1, "Items": [
    {"ErrorCode": 403, "ResponsePagePath": "/error.html", "ResponseCode": "404", "ErrorCachingMinTTL": 10}]}
}
JSON
read -r DIST_ID DOMAIN < <(aws cloudfront create-distribution --distribution-config file:///tmp/lab06-dist.json \
  --query 'Distribution.[Id,DomainName]' --output text)
DIST_ARN="arn:aws:cloudfront::${ACCOUNT}:distribution/${DIST_ID}"

echo "== 4. Bucket policy: ONLY this CloudFront distribution may read objects"
aws s3api put-bucket-policy --bucket "$BUCKET" --policy "{
 \"Version\":\"2012-10-17\",
 \"Statement\":[{\"Sid\":\"AllowCloudFrontServicePrincipal\",\"Effect\":\"Allow\",
  \"Principal\":{\"Service\":\"cloudfront.amazonaws.com\"},\"Action\":\"s3:GetObject\",
  \"Resource\":\"arn:aws:s3:::${BUCKET}/*\",
  \"Condition\":{\"StringEquals\":{\"AWS:SourceArn\":\"${DIST_ARN}\"}}}]}"
echo "$BUCKET $DIST_ID $OAC" > "$HERE/.state"

echo "== 5. Wait for the distribution to deploy (about 3-6 minutes)"
aws cloudfront wait distribution-deployed --id "$DIST_ID"
echo "URL: https://$DOMAIN"
