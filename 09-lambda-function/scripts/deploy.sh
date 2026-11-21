#!/usr/bin/env bash
# Lab 09 - create a Lambda function with its IAM execution role, invoke it, read its logs.
set -euo pipefail
REGION="${AWS_REGION:-ap-southeast-2}"
FN=lab-09-hello
ROLE=lab-09-lambda-role
HERE="$(cd "$(dirname "$0")" && pwd)"

echo "== 1. IAM execution role (lets Lambda run and write logs, nothing else)"
aws iam create-role --role-name $ROLE \
  --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"lambda.amazonaws.com"},"Action":"sts:AssumeRole"}]}' \
  --tags Key=Project,Value=aws-hands-on-labs Key=Lab,Value=09 --query Role.RoleName --output text
aws iam attach-role-policy --role-name $ROLE --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole
ROLE_ARN=$(aws iam get-role --role-name $ROLE --query Role.Arn --output text)
sleep 10   # IAM is eventually consistent

echo "== 2. Package and create the function"
(cd "$HERE/../src" && zip -q -j /tmp/lab09.zip lambda_function.py)
aws lambda create-function --function-name $FN --runtime python3.13 --handler lambda_function.lambda_handler \
  --role "$ROLE_ARN" --zip-file fileb:///tmp/lab09.zip --timeout 10 --memory-size 128 --region "$REGION" \
  --tags Project=aws-hands-on-labs,Lab=09 --query '{Name:FunctionName,Runtime:Runtime,Memory:MemorySize}' --output table
aws lambda wait function-active-v2 --function-name $FN

echo "== 3. Invoke it"
aws lambda invoke --function-name $FN --payload '{"name":"AWS Portfolio"}' --cli-binary-format raw-in-base64-out /tmp/lab09-out.json \
  --query '{StatusCode:StatusCode,Error:FunctionError}' --output table
cat /tmp/lab09-out.json; echo

echo "== 4. Read the logs from CloudWatch"
sleep 8
aws logs filter-log-events --log-group-name /aws/lambda/$FN --query 'events[].message' --output text | tr '\t' '\n' | grep -vE '^$'
