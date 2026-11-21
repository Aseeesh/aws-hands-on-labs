#!/usr/bin/env bash
# Deletes EVERY version and delete marker, then the bucket.
set -euo pipefail
F="$(dirname "$0")/.bucket-name"; BUCKET="${1:-$(cat "$F")}"
for kind in Versions DeleteMarkers; do
  while :; do
    OBJ=$(aws s3api list-object-versions --bucket "$BUCKET" --max-items 500 \
      --query "{Objects: ${kind}[].{Key:Key,VersionId:VersionId}}" --output json)
    [ "$OBJ" = '{"Objects":null}' ] || [ "$OBJ" = '{"Objects": null}' ] && break
    echo "$OBJ" | grep -q '"Key"' || break
    aws s3api delete-objects --bucket "$BUCKET" --delete "$OBJ" >/dev/null
  done
done
aws s3api delete-bucket --bucket "$BUCKET"; rm -f "$F"; echo "Deleted $BUCKET"
