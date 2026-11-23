#!/usr/bin/env bash
# Lab 25 - a CloudWatch dashboard and two alarms watching earlier labs' live resources.
set -euo pipefail
REGION="${AWS_REGION:-ap-southeast-2}"
HERE="$(cd "$(dirname "$0")" && pwd)"
A1=lab-25-heartbeat-stopped     # dead-man's switch: fires if Lab 19 stops running
A2=lab-25-heartbeat-errors      # fires if the function throws errors

echo "== 1. Alarm: heartbeat stopped (fewer than 1 invocation in 15 min; missing data counts as bad)"
aws cloudwatch put-metric-alarm --alarm-name $A1 \
  --alarm-description "Lab 25: lab-19-heartbeat has not run in 15 minutes" \
  --namespace AWS/Lambda --metric-name Invocations --dimensions Name=FunctionName,Value=lab-19-heartbeat \
  --statistic Sum --period 900 --evaluation-periods 1 --threshold 1 --comparison-operator LessThanThreshold \
  --treat-missing-data breaching --tags Key=Project,Value=aws-hands-on-labs Key=Lab,Value=25

echo "== 2. Alarm: heartbeat errors (any error in 5 min)"
aws cloudwatch put-metric-alarm --alarm-name $A2 \
  --alarm-description "Lab 25: lab-19-heartbeat threw an error" \
  --namespace AWS/Lambda --metric-name Errors --dimensions Name=FunctionName,Value=lab-19-heartbeat \
  --statistic Sum --period 300 --evaluation-periods 1 --threshold 1 --comparison-operator GreaterThanOrEqualToThreshold \
  --treat-missing-data notBreaching --tags Key=Project,Value=aws-hands-on-labs Key=Lab,Value=25

echo "== 3. Dashboard"
BODY=$(sed -e "s#__ALARM1__#arn:aws:cloudwatch:$REGION:$(aws sts get-caller-identity --query Account --output text):alarm:$A1#" \
           -e "s#__ALARM2__#arn:aws:cloudwatch:$REGION:$(aws sts get-caller-identity --query Account --output text):alarm:$A2#" "$HERE/../src/dashboard.json")
aws cloudwatch put-dashboard --dashboard-name lab-25-overview --dashboard-body "$BODY" --query DashboardValidationMessages --output text

echo "== 4. Prove an alarm can fire: force ALARM state by hand, then let CloudWatch re-evaluate"
aws cloudwatch set-alarm-state --alarm-name $A2 --state-value ALARM --state-reason "Lab 25 manual test"
aws cloudwatch describe-alarms --alarm-names $A2 --query 'MetricAlarms[].{Alarm:AlarmName,State:StateValue,Reason:StateReason}' --output table
echo "(CloudWatch re-evaluates within a few minutes and returns it to OK)"
