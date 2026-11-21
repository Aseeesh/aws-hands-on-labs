#!/usr/bin/env bash
# Deletes everything deploy.sh created, in dependency order.
set -uo pipefail
read -r VPC IGW RT_PUB RT_PRV PUB_A PUB_B PRV_A PRV_B < "$(dirname "$0")/.state"
for rt in $RT_PUB $RT_PRV; do
  for a in $(aws ec2 describe-route-tables --route-table-ids $rt --query 'RouteTables[0].Associations[?!Main].RouteTableAssociationId' --output text); do
    aws ec2 disassociate-route-table --association-id "$a"
  done
  aws ec2 delete-route-table --route-table-id $rt
done
for s in $PUB_A $PUB_B $PRV_A $PRV_B; do aws ec2 delete-subnet --subnet-id $s; done
aws ec2 detach-internet-gateway --internet-gateway-id $IGW --vpc-id $VPC
aws ec2 delete-internet-gateway --internet-gateway-id $IGW
aws ec2 delete-vpc --vpc-id $VPC && rm -f "$(dirname "$0")/.state"
echo "Lab 12 resources deleted"
