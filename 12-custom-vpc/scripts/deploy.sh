#!/usr/bin/env bash
# Lab 12 - custom VPC: 2 public + 2 private subnets in 2 AZs, internet gateway, route tables.
# No NAT Gateway (it bills ~$0.045/hour); see README for where it would go.
set -euo pipefail
REGION="${AWS_REGION:-ap-southeast-2}"
HERE="$(cd "$(dirname "$0")" && pwd)"
P='{Key=Project,Value=aws-hands-on-labs},{Key=Lab,Value=12}'
tag() { echo "ResourceType=$1,Tags=[$P,{Key=Name,Value=$2}]"; }
AZ_A="${REGION}a"; AZ_B="${REGION}b"

echo "== 1. VPC 10.20.0.0/16 (65,536 addresses)"
VPC=$(aws ec2 create-vpc --cidr-block 10.20.0.0/16 --tag-specifications "$(tag vpc lab-12-vpc)" --query Vpc.VpcId --output text)
aws ec2 modify-vpc-attribute --vpc-id "$VPC" --enable-dns-hostnames '{"Value":true}'

echo "== 2. Four subnets (2 public, 2 private) across two Availability Zones"
mk() { aws ec2 create-subnet --vpc-id "$VPC" --cidr-block "$1" --availability-zone "$2" --tag-specifications "$(tag subnet "$3")" --query Subnet.SubnetId --output text; }
PUB_A=$(mk 10.20.1.0/24  $AZ_A lab-12-public-a)
PUB_B=$(mk 10.20.2.0/24  $AZ_B lab-12-public-b)
PRV_A=$(mk 10.20.11.0/24 $AZ_A lab-12-private-a)
PRV_B=$(mk 10.20.12.0/24 $AZ_B lab-12-private-b)
for s in $PUB_A $PUB_B; do aws ec2 modify-subnet-attribute --subnet-id "$s" --map-public-ip-on-launch; done

echo "== 3. Internet gateway attached to the VPC"
IGW=$(aws ec2 create-internet-gateway --tag-specifications "$(tag internet-gateway lab-12-igw)" --query InternetGateway.InternetGatewayId --output text)
aws ec2 attach-internet-gateway --internet-gateway-id "$IGW" --vpc-id "$VPC"

echo "== 4. Public route table: 0.0.0.0/0 -> internet gateway"
RT_PUB=$(aws ec2 create-route-table --vpc-id "$VPC" --tag-specifications "$(tag route-table lab-12-public-rt)" --query RouteTable.RouteTableId --output text)
aws ec2 create-route --route-table-id "$RT_PUB" --destination-cidr-block 0.0.0.0/0 --gateway-id "$IGW" >/dev/null
for s in $PUB_A $PUB_B; do aws ec2 associate-route-table --route-table-id "$RT_PUB" --subnet-id "$s" >/dev/null; done

echo "== 5. Private route table: local traffic only (no route to the internet)"
RT_PRV=$(aws ec2 create-route-table --vpc-id "$VPC" --tag-specifications "$(tag route-table lab-12-private-rt)" --query RouteTable.RouteTableId --output text)
for s in $PRV_A $PRV_B; do aws ec2 associate-route-table --route-table-id "$RT_PRV" --subnet-id "$s" >/dev/null; done

echo "$VPC $IGW $RT_PUB $RT_PRV $PUB_A $PUB_B $PRV_A $PRV_B" > "$HERE/.state"
echo "== Done: vpc=$VPC"
