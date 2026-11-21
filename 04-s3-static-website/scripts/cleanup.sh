#!/usr/bin/env bash
# Lab 04 cleanup - empties and deletes the bucket created by deploy.sh
set -euo pipefail
F="$(dirname "$0")/.bucket-name"
BUCKET="${1:-$(cat "$F")}"
aws s3 rm "s3://${BUCKET}" --recursive
aws s3api delete-bucket --bucket "$BUCKET"
rm -f "$F"
echo "Deleted $BUCKET"
