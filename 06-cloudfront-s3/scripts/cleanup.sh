#!/usr/bin/env bash
# CloudFront must be disabled and fully deployed before it can be deleted.
set -uo pipefail
read -r BUCKET DIST OAC < "$(dirname "$0")/.state"
ETAG=$(aws cloudfront get-distribution-config --id "$DIST" --query ETag --output text)
aws cloudfront get-distribution-config --id "$DIST" --query DistributionConfig | python3 -c 'import json,sys;c=json.load(sys.stdin);c["Enabled"]=False;print(json.dumps(c))' > /tmp/lab06-disabled.json
aws cloudfront update-distribution --id "$DIST" --if-match "$ETAG" --distribution-config file:///tmp/lab06-disabled.json >/dev/null
aws cloudfront wait distribution-deployed --id "$DIST"
aws cloudfront delete-distribution --id "$DIST" --if-match "$(aws cloudfront get-distribution --id "$DIST" --query ETag --output text)"
aws cloudfront delete-origin-access-control --id "$OAC" --if-match "$(aws cloudfront get-origin-access-control --id "$OAC" --query ETag --output text)"
aws s3 rm "s3://$BUCKET" --recursive --only-show-errors && aws s3api delete-bucket --bucket "$BUCKET"
rm -f "$(dirname "$0")/.state"; echo "Lab 06 resources deleted"
