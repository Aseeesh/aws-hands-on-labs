#!/usr/bin/env bash
set -euo pipefail
echo "== alarms"; aws cloudwatch describe-alarms --alarm-name-prefix lab-25- \
  --query 'MetricAlarms[].{Alarm:AlarmName,State:StateValue,Metric:MetricName,Threshold:Threshold}' --output table
echo "== alarm history for the error alarm"
aws cloudwatch describe-alarm-history --alarm-name lab-25-heartbeat-errors --history-item-type StateUpdate \
  --query 'AlarmHistoryItems[].[Timestamp,HistorySummary]' --output text
echo "== dashboard"; aws cloudwatch list-dashboards --dashboard-name-prefix lab-25- --query 'DashboardEntries[].DashboardName' --output text
