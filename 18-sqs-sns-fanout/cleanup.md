# Clean up - Lab 18

This lab is left running. Idle queues and topics cost nothing, but delete them when you no longer need the demo.

## Script
```bash
cd 18-sqs-sns-fanout
./scripts/cleanup.sh
```

## Console
1. [SNS → Subscriptions](https://console.aws.amazon.com/sns/v3/home#/subscriptions): delete both `lab-18-orders` subscriptions.
2. [SNS → Topics](https://console.aws.amazon.com/sns/v3/home#/topics): delete `lab-18-orders`.
3. [SQS → Queues](https://console.aws.amazon.com/sqs/v3/home#/queues): delete `lab-18-billing`, `lab-18-shipping`, `lab-18-dlq`.

## Verify it is gone
```bash
aws sns list-topics --query "Topics[?contains(TopicArn,'lab-18')]"
aws sqs list-queues --queue-name-prefix lab-18
```
Both return nothing. Wait ~60 seconds before re-creating queues with the same names.
