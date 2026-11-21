#!/usr/bin/env bash
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
[ -f "$HERE/.state" ] && aws apigateway delete-rest-api --rest-api-id "$(cat "$HERE/.state")" && rm -f "$HERE/.state"
aws lambda delete-function --function-name lab-10-api-handler
aws logs delete-log-group --log-group-name /aws/lambda/lab-10-api-handler 2>/dev/null
aws iam detach-role-policy --role-name lab-10-lambda-role --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole
aws iam delete-role --role-name lab-10-lambda-role
echo "Lab 10 resources deleted"
