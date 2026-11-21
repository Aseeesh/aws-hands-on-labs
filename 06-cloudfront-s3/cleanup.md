# Cleanup

```bash
AWS_PROFILE=lab ./scripts/cleanup.sh
```
A CloudFront distribution must first be **disabled** and fully redeployed (a few minutes) before it can be deleted, so the script: disables it, waits, deletes the distribution, deletes the Origin Access Control, empties and deletes the bucket.

Verify:
```bash
aws cloudfront get-distribution --id <id>      # NoSuchDistribution
aws s3api head-bucket --bucket <bucket>        # 404
```
Console: CloudFront → select the distribution → **Disable** → wait until *Last modified* shows a date → **Delete**; then delete the OAC under *Security → Origin access*; then empty and delete the bucket.
