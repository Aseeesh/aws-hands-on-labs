#!/usr/bin/env bash
set -uo pipefail
read -r IID SG < "$(dirname "$0")/.state"
aws ec2 terminate-instances --instance-ids "$IID" --query 'TerminatingInstances[0].CurrentState.Name' --output text
aws ec2 wait instance-terminated --instance-ids "$IID"
aws ec2 delete-security-group --group-id "$SG" && rm -f "$(dirname "$0")/.state"
echo "Lab 07 resources deleted"
