# Cleanup - Lab 19

**Do this when you finish: the rule keeps invoking the function every 5 minutes.**

```bash
AWS_PROFILE=lab ./scripts/cleanup.sh
```
Removes the rule's target, the rule, the function, its CloudWatch log group (Lambda does not remove it), and the IAM role.

Or in the console: EventBridge → Scheduled rules → select the rule → **Delete**; then Lambda → delete `lab-19-heartbeat`; CloudWatch → delete the log group; IAM → delete `lab-19-lambda-role`.

Verify:
```bash
aws events describe-rule --name lab-19-every-5-minutes   # ResourceNotFoundException
aws lambda get-function --function-name lab-19-heartbeat # ResourceNotFoundException
```
To pause instead of delete: `aws events disable-rule --name lab-19-every-5-minutes`.
