#!/usr/bin/env bash
# Lab 10 - REST API (API Gateway) in front of a Lambda function.
set -euo pipefail
REGION="${AWS_REGION:-ap-southeast-2}"
FN=lab-10-api-handler; ROLE=lab-10-lambda-role; API=lab-10-hello-api
HERE="$(cd "$(dirname "$0")" && pwd)"
ACCOUNT=$(aws sts get-caller-identity --query Account --output text)

echo "== 1. Role + function"
aws iam create-role --role-name $ROLE \
  --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"lambda.amazonaws.com"},"Action":"sts:AssumeRole"}]}' \
  --tags Key=Project,Value=aws-hands-on-labs Key=Lab,Value=10 --query Role.RoleName --output text
aws iam attach-role-policy --role-name $ROLE --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole
sleep 10
(cd "$HERE/../src" && zip -q -j /tmp/lab10.zip lambda_function.py)
FN_ARN=$(aws lambda create-function --function-name $FN --runtime python3.13 --handler lambda_function.lambda_handler \
  --role "arn:aws:iam::${ACCOUNT}:role/${ROLE}" --zip-file fileb:///tmp/lab10.zip --timeout 10 \
  --tags Project=aws-hands-on-labs,Lab=10 --query FunctionArn --output text)
aws lambda wait function-active-v2 --function-name $FN

echo "== 2. REST API with /hello and /quote (GET) using Lambda proxy integration"
API_ID=$(aws apigateway create-rest-api --name $API --tags Project=aws-hands-on-labs,Lab=10 --query id --output text)
ROOT=$(aws apigateway get-resources --rest-api-id $API_ID --query 'items[0].id' --output text)
for P in hello quote; do
  RID=$(aws apigateway create-resource --rest-api-id $API_ID --parent-id $ROOT --path-part $P --query id --output text)
  aws apigateway put-method --rest-api-id $API_ID --resource-id $RID --http-method GET --authorization-type NONE >/dev/null
  aws apigateway put-integration --rest-api-id $API_ID --resource-id $RID --http-method GET --type AWS_PROXY \
    --integration-http-method POST \
    --uri "arn:aws:apigateway:${REGION}:lambda:path/2015-03-31/functions/${FN_ARN}/invocations" >/dev/null
done

echo "== 3. Allow API Gateway to invoke the function"
aws lambda add-permission --function-name $FN --statement-id apigw-invoke --action lambda:InvokeFunction \
  --principal apigateway.amazonaws.com --source-arn "arn:aws:execute-api:${REGION}:${ACCOUNT}:${API_ID}/*/GET/*" --query Statement --output text >/dev/null

echo "== 4. Deploy to stage 'prod'"
aws apigateway create-deployment --rest-api-id $API_ID --stage-name prod --query id --output text >/dev/null
echo "== 4b. Throttle the stage (public, no auth): 10 req/s steady, burst 20"
aws apigateway update-stage --rest-api-id $API_ID --stage-name prod --patch-operations \
  'op=replace,path=/*/*/throttling/rateLimit,value=10' 'op=replace,path=/*/*/throttling/burstLimit,value=20' \
  --query '{stage:stageName,throttling:methodSettings."*/*".throttlingRateLimit}' --output json
echo "$API_ID" > "$HERE/.state"
URL="https://${API_ID}.execute-api.${REGION}.amazonaws.com/prod"
echo "Invoke URL: $URL"
sleep 5
echo "== 5. Test"
curl -s -w "  [HTTP %{http_code}]\n" "$URL/hello?name=Portfolio"
curl -s -w "  [HTTP %{http_code}]\n" "$URL/hello"
curl -s -w "  [HTTP %{http_code}]\n" "$URL/quote"
curl -s -w "  [HTTP %{http_code}]\n" "$URL/missing"
