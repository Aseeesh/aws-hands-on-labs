#!/usr/bin/env bash
set -uo pipefail
read -r TOPIC BILL SHIP DLQ < "$(dirname "$0")/.state"
for sub in $(aws sns list-subscriptions-by-topic --topic-arn "$TOPIC" --query 'Subscriptions[].SubscriptionArn' --output text); do aws sns unsubscribe --subscription-arn "$sub"; done
aws sns delete-topic --topic-arn "$TOPIC"
for q in "$BILL" "$SHIP" "$DLQ"; do aws sqs delete-queue --queue-url "$q"; done
rm -f "$(dirname "$0")/.state"; echo "Lab 18 resources deleted"
