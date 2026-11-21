#!/usr/bin/env bash
# Lab 16 - create an on-demand DynamoDB table with a global secondary index.
set -euo pipefail
REGION="${AWS_REGION:-ap-southeast-2}"
TABLE=lab-16-books
aws dynamodb create-table --table-name $TABLE --region "$REGION" \
  --attribute-definitions AttributeName=book_id,AttributeType=S AttributeName=author,AttributeType=S \
  --key-schema AttributeName=book_id,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --global-secondary-indexes '[{"IndexName":"author-index","KeySchema":[{"AttributeName":"author","KeyType":"HASH"}],"Projection":{"ProjectionType":"ALL"}}]' \
  --tags Key=Project,Value=aws-hands-on-labs Key=Lab,Value=16 \
  --query 'TableDescription.{Table:TableName,Billing:BillingModeSummary.BillingMode,Status:TableStatus}' --output table
aws dynamodb wait table-exists --table-name $TABLE --region "$REGION"
echo "Table $TABLE is ACTIVE"
