# Cleanup
```bash
AWS_PROFILE=lab ./scripts/cleanup.sh
```
Deletes the REST API, the function, its log group and the IAM role. Verify:
```bash
aws apigateway get-rest-apis --query "items[?name=='lab-10-hello-api']"   # []
aws lambda get-function --function-name lab-10-api-handler                # ResourceNotFoundException
```
