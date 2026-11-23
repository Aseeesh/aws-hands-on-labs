#!/usr/bin/env bash
set -uo pipefail
aws cloudwatch delete-alarms --alarm-names lab-25-heartbeat-stopped lab-25-heartbeat-errors
aws cloudwatch delete-dashboards --dashboard-names lab-25-overview
echo "Lab 25 resources deleted"
