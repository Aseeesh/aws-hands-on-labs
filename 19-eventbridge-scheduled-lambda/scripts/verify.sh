#!/usr/bin/env bash
# Shows that the schedule really fired: rule config, target, log lines and invocation metric.
set -euo pipefail
FN=lab-19-heartbeat; RULE=lab-19-every-5-minutes
echo "== rule";   aws events describe-rule --name $RULE --query '{State:State,Schedule:ScheduleExpression}' --output table
echo "== target"; aws events list-targets-by-rule --rule $RULE --query 'Targets[].Id' --output text
echo "== log lines written by the scheduled runs"
aws logs filter-log-events --log-group-name /aws/lambda/$FN --filter-pattern '"lab-19-heartbeat"' \
  --query 'events[].message' --output text | tr '\t' '\n' | grep '^{'
echo "== invocations in the last hour (CloudWatch metric)"
aws cloudwatch get-metric-statistics --namespace AWS/Lambda --metric-name Invocations \
  --dimensions Name=FunctionName,Value=$FN --start-time "$(date -u -v-1H +%FT%TZ)" --end-time "$(date -u +%FT%TZ)" \
  --period 3600 --statistics Sum --query 'Datapoints[].Sum' --output text
