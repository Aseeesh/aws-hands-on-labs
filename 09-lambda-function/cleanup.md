# Cleanup
```bash
AWS_PROFILE=lab ./scripts/cleanup.sh
```
Deletes the function, its CloudWatch log group (Lambda does not remove it), and the IAM role. Verify:
```bash
aws lambda get-function --function-name lab-09-hello      # ResourceNotFoundException
aws iam get-role --role-name lab-09-lambda-role           # NoSuchEntity
```
