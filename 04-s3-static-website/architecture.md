# Architecture

```
 Browser ──HTTP──▶ S3 website endpoint ──▶ Bucket (index.html, error.html)
                     (ap-southeast-2)        policy: public s3:GetObject only
```

One bucket, one bucket policy, static website hosting turned on. No servers to manage.
