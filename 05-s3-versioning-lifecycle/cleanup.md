# Cleanup

```bash
AWS_PROFILE=lab ./scripts/cleanup.sh
```
Deletes all object versions and delete markers, then the bucket. Verify (expect a 404):
```bash
aws s3api head-bucket --bucket <your-bucket-name>
```
Console: bucket → **Objects → Show versions** → select all → Delete, then delete the bucket.
