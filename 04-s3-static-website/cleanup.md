# Cleanup

Deletes the bucket and its files (S3 buckets must be emptied before deletion):

```bash
AWS_PROFILE=lab ./scripts/cleanup.sh
```

Verify it is gone (should print `NoSuchBucket` / 404):

```bash
aws s3api head-bucket --bucket <your-bucket-name>
```

Console: S3 → Buckets → select the bucket → **Empty** → then **Delete**.
