#!/usr/bin/env bash
# Lab 19 - run a Lambda function on a schedule with an EventBridge rule.
set -euo pipefail
REGION="${AWS_REGION:-ap-southeast-2}"
FN=lab-19-heartbeat
ROLE=lab-19-lambda-role
RULE=lab-19-every-5-minutes
HERE="$(cd "$(dirname "$0")" && pwd)"

echo "== 1. IAM execution role (logs only)"
aws iam create-role --role-name $ROLE \
  --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"lambda.amazonaws.com"},"Action":"sts:AssumeRole"}]}' \
  --tags Key=Project,Value=aws-hands-on-labs Key=Lab,Value=19 --query Role.RoleName --output text
aws iam attach-role-policy --role-name $ROLE --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole
ROLE_ARN=$(aws iam get-role --role-name $ROLE --query Role.Arn --output text)
sleep 10   # IAM is eventually consistent

echo "== 2. Create the function"
(cd "$HERE/../src" && zip -q -j /tmp/lab19.zip lambda_function.py)
aws lambda create-function --function-name $FN --runtime python3.13 --handler lambda_function.lambda_handler \
  --role "$ROLE_ARN" --zip-file fileb:///tmp/lab19.zip --timeout 10 --memory-size 128 --region "$REGION" \
  --tags Project=aws-hands-on-labs,Lab=19 --query '{Name:FunctionName,Runtime:Runtime}' --output table
aws lambda wait function-active-v2 --function-name $FN
FN_ARN=$(aws lambda get-function --function-name $FN --query Configuration.FunctionArn --output text)

echo "== 3. EventBridge rule on a schedule"
RULE_ARN=$(aws events put-rule --name $RULE --schedule-expression 'rate(5 minutes)' --state ENABLED \
  --description "Lab 19: invoke lab-19-heartbeat every 5 minutes" --query RuleArn --output text)
echo "$RULE_ARN"

echo "== 4. Allow EventBridge to invoke the function, then set it as the rule target"
aws lambda add-permission --function-name $FN --statement-id eventbridge-invoke \
  --action lambda:InvokeFunction --principal events.amazonaws.com --source-arn "$RULE_ARN" \
  --query Statement --output text
aws events put-targets --rule $RULE --targets "Id=heartbeat,Arn=$FN_ARN" \
  --query '{Failed:FailedEntryCount}' --output table
date -u +%FT%TZ > "$HERE/.state"
echo "Rule is live. The first run happens within 5 minutes; see verify.sh"
