#!/usr/bin/env bash
# Lab 18 - SNS topic fanning out to two SQS queues (one with a filter) + a dead-letter queue.
set -euo pipefail
REGION="${AWS_REGION:-ap-southeast-2}"
HERE="$(cd "$(dirname "$0")" && pwd)"
ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
TAGS='Project=aws-hands-on-labs,Lab=18'

echo "== 1. SNS topic"
TOPIC=$(aws sns create-topic --name lab-18-orders --tags Key=Project,Value=aws-hands-on-labs Key=Lab,Value=18 --query TopicArn --output text)

echo "== 2. Dead-letter queue + two work queues"
mkq() { aws sqs create-queue --queue-name "$1" --attributes "${2:-VisibilityTimeout=30}" --tags "$TAGS" --query QueueUrl --output text; }
arn() { aws sqs get-queue-attributes --queue-url "$1" --attribute-names QueueArn --query Attributes.QueueArn --output text; }
DLQ_URL=$(mkq lab-18-dlq);  DLQ_ARN=$(arn "$DLQ_URL")
REDRIVE=$(python3 -c "import json;print(json.dumps({'deadLetterTargetArn':'$DLQ_ARN','maxReceiveCount':3}))")
attrs() { python3 -c "import json,sys;print(json.dumps({'RedrivePolicy':sys.argv[1],'VisibilityTimeout':'30'}))" "$REDRIVE"; }
echo "$(attrs)" > /tmp/lab18-q-attrs.json
BILL_URL=$(aws sqs create-queue --queue-name lab-18-billing  --attributes file:///tmp/lab18-q-attrs.json --tags "$TAGS" --query QueueUrl --output text)
SHIP_URL=$(aws sqs create-queue --queue-name lab-18-shipping --attributes file:///tmp/lab18-q-attrs.json --tags "$TAGS" --query QueueUrl --output text)
BILL_ARN=$(arn "$BILL_URL"); SHIP_ARN=$(arn "$SHIP_URL")

echo "== 3. Queue policies: allow ONLY this topic to send messages"
for pair in "$BILL_URL $BILL_ARN" "$SHIP_URL $SHIP_ARN"; do
  set -- $pair
  python3 - "$1" "$2" "$TOPIC" <<'PY' > /tmp/lab18-pol.json
import json,sys
url,arn,topic=sys.argv[1:4]
pol={"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"sns.amazonaws.com"},
 "Action":"sqs:SendMessage","Resource":arn,"Condition":{"ArnEquals":{"aws:SourceArn":topic}}}]}
print(json.dumps({"Policy":json.dumps(pol)}))
PY
  aws sqs set-queue-attributes --queue-url "$1" --attributes file:///tmp/lab18-pol.json
done

echo "== 4. Subscribe both queues (raw delivery); shipping only gets type=physical"
aws sns subscribe --topic-arn "$TOPIC" --protocol sqs --notification-endpoint "$BILL_ARN" \
  --attributes RawMessageDelivery=true --query SubscriptionArn --output text >/dev/null
aws sns subscribe --topic-arn "$TOPIC" --protocol sqs --notification-endpoint "$SHIP_ARN" \
  --attributes '{"RawMessageDelivery":"true","FilterPolicy":"{\"type\":[\"physical\"]}"}' --query SubscriptionArn --output text >/dev/null

echo "$TOPIC $BILL_URL $SHIP_URL $DLQ_URL" > "$HERE/.state"

echo "== 5. Publish 3 orders (1001 physical, 1002 digital, 1003 physical)"
pub() { aws sns publish --topic-arn "$TOPIC" --message "$2" \
  --message-attributes "{\"type\":{\"DataType\":\"String\",\"StringValue\":\"$1\"}}" --query MessageId --output text >/dev/null; echo "published: $2"; }
pub physical '{"order_id":1001,"item":"Keyboard","type":"physical"}'
pub digital  '{"order_id":1002,"item":"E-book","type":"digital"}'
pub physical '{"order_id":1003,"item":"Monitor","type":"physical"}'
sleep 5

echo "== 6. Read each queue once (30 s visibility timeout; nothing is deleted, so messages reappear)"
# NOTE: do NOT peek with --visibility-timeout 0 on a queue that has a redrive policy: every receive
# raises the receive count and after maxReceiveCount the message is moved to the dead-letter queue.
peek() {  # receive in a loop: one call returns only a sample, and received messages are hidden for 30 s
  echo "-- $1:"
  for i in 1 2 3 4; do
    aws sqs receive-message --queue-url "$2" --max-number-of-messages 10 --wait-time-seconds 2 \
      --query 'Messages[].[MessageId,Body]' --output text
  done | grep -v '^None' | sort -u -k1,1 | cut -f2
}
peek "lab-18-billing  (expects 3 orders)" "$BILL_URL"
peek "lab-18-shipping (expects 2 physical orders only)" "$SHIP_URL"
echo "-- counts (visible + in-flight):"
for q in "$BILL_URL" "$SHIP_URL" "$DLQ_URL"; do
  echo "$(basename "$q"): $(aws sqs get-queue-attributes --queue-url "$q" --attribute-names ApproximateNumberOfMessages ApproximateNumberOfMessagesNotVisible \
    --query 'Attributes.[ApproximateNumberOfMessages,ApproximateNumberOfMessagesNotVisible]' --output text | tr '\t' ' ')"
done
