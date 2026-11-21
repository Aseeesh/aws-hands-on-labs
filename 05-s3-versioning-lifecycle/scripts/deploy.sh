#!/usr/bin/env bash
# Lab 05 - S3 versioning, delete-marker recovery and lifecycle rules.
set -euo pipefail
REGION="${AWS_REGION:-ap-southeast-2}"
BUCKET="lab-05-versioning-$(openssl rand -hex 3)"
HERE="$(cd "$(dirname "$0")" && pwd)"
TMP="$(mktemp -d)"

echo "== 1. Create bucket $BUCKET (private by default)"
aws s3api create-bucket --bucket "$BUCKET" --region "$REGION" \
  --create-bucket-configuration LocationConstraint="$REGION" >/dev/null
echo "$BUCKET" > "$HERE/.bucket-name"
aws s3api put-bucket-tagging --bucket "$BUCKET" \
  --tagging 'TagSet=[{Key=Project,Value=aws-hands-on-labs},{Key=Lab,Value=05}]'

echo "== 2. Turn on versioning"
aws s3api put-bucket-versioning --bucket "$BUCKET" --versioning-configuration Status=Enabled
aws s3api get-bucket-versioning --bucket "$BUCKET"

echo "== 3. Upload the same key 3 times -> 3 versions"
for v in 1 2 3; do
  echo "report version $v" > "$TMP/report.txt"
  aws s3api put-object --bucket "$BUCKET" --key report.txt --body "$TMP/report.txt" \
    --query VersionId --output text
done
aws s3api list-object-versions --bucket "$BUCKET" \
  --query 'Versions[].{Key:Key,VersionId:VersionId,IsLatest:IsLatest}' --output table

echo "== 4. Normal delete adds a delete marker (data is NOT lost)"
aws s3api delete-object --bucket "$BUCKET" --key report.txt --query '{DeleteMarker:DeleteMarker,VersionId:VersionId}'
aws s3api get-object --bucket "$BUCKET" --key report.txt "$TMP/x" 2>&1 | tail -1 || true

echo "== 5. Recover: delete the delete marker"
MARKER=$(aws s3api list-object-versions --bucket "$BUCKET" --query 'DeleteMarkers[?IsLatest==`true`].VersionId | [0]' --output text)
aws s3api delete-object --bucket "$BUCKET" --key report.txt --version-id "$MARKER" >/dev/null
aws s3api get-object --bucket "$BUCKET" --key report.txt "$TMP/restored.txt" >/dev/null
echo "restored content: $(cat "$TMP/restored.txt")"

echo "== 6. Add lifecycle rule"
aws s3api put-bucket-lifecycle-configuration --bucket "$BUCKET" \
  --lifecycle-configuration "file://$HERE/../src/lifecycle.json"
aws s3api get-bucket-lifecycle-configuration --bucket "$BUCKET" \
  --query 'Rules[].{ID:ID,Status:Status,IA_after_days:Transitions[0].Days,ExpireOldVersionsAfter:NoncurrentVersionExpiration.NoncurrentDays}' --output table
rm -rf "$TMP"
