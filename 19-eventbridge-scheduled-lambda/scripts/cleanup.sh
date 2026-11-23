#!/usr/bin/env bash
set -uo pipefail
aws events remove-targets --rule lab-19-every-5-minutes --ids heartbeat
aws events delete-rule --name lab-19-every-5-minutes
aws lambda delete-function --function-name lab-19-heartbeat
aws logs delete-log-group --log-group-name /aws/lambda/lab-19-heartbeat
aws iam detach-role-policy --role-name lab-19-lambda-role --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole
aws iam delete-role --role-name lab-19-lambda-role
echo "Lab 19 resources deleted"
