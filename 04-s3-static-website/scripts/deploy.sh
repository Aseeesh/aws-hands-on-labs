#!/usr/bin/env bash
# Lab 04 - deploy an S3 static website. Usage: AWS_PROFILE=lab ./deploy.sh
set -euo pipefail
REGION="${AWS_REGION:-ap-southeast-2}"
SUFFIX="$(openssl rand -hex 3)"
BUCKET="lab-04-static-site-${SUFFIX}"
SRC="$(cd "$(dirname "$0")/../src" && pwd)"

echo "1/6 Create bucket $BUCKET"
aws s3api create-bucket --bucket "$BUCKET" --region "$REGION" \
  --create-bucket-configuration LocationConstraint="$REGION"
aws s3api put-bucket-tagging --bucket "$BUCKET" \
  --tagging 'TagSet=[{Key=Project,Value=aws-hands-on-labs},{Key=Lab,Value=04}]'

echo "2/6 Allow public reads (turn off Block Public Access for THIS bucket only)"
aws s3api put-public-access-block --bucket "$BUCKET" \
  --public-access-block-configuration BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=false,RestrictPublicBuckets=false

echo "3/6 Attach read-only public bucket policy"
aws s3api put-bucket-policy --bucket "$BUCKET" --policy "{
  \"Version\":\"2012-10-17\",
  \"Statement\":[{\"Sid\":\"PublicRead\",\"Effect\":\"Allow\",\"Principal\":\"*\",
  \"Action\":\"s3:GetObject\",\"Resource\":\"arn:aws:s3:::${BUCKET}/*\"}]}"

echo "4/6 Enable static website hosting"
aws s3api put-bucket-website --bucket "$BUCKET" --website-configuration \
  '{"IndexDocument":{"Suffix":"index.html"},"ErrorDocument":{"Key":"error.html"}}'

echo "5/6 Upload site files"
aws s3 sync "$SRC" "s3://${BUCKET}/" --delete

echo "6/6 Done"
echo "$BUCKET" > "$(dirname "$0")/.bucket-name"
echo "URL: http://${BUCKET}.s3-website-${REGION}.amazonaws.com"
