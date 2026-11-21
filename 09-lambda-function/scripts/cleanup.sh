#!/usr/bin/env bash
set -uo pipefail
aws lambda delete-function --function-name lab-09-hello
aws logs delete-log-group --log-group-name /aws/lambda/lab-09-hello
aws iam detach-role-policy --role-name lab-09-lambda-role --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole
aws iam delete-role --role-name lab-09-lambda-role
echo "Lab 09 resources deleted"
