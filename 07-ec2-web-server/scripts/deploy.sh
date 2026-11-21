#!/usr/bin/env bash
# Lab 07 - launch an EC2 instance running nginx, reachable on port 80 only. Usage: AWS_PROFILE=lab ./deploy.sh
set -euo pipefail
REGION="${AWS_REGION:-ap-southeast-2}"
HERE="$(cd "$(dirname "$0")" && pwd)"
TAGS='Key=Project,Value=aws-hands-on-labs'

echo "== 1. Find the default VPC and the latest Amazon Linux 2023 AMI"
VPC=$(aws ec2 describe-vpcs --filters Name=is-default,Values=true --query 'Vpcs[0].VpcId' --output text)
AMI=$(aws ssm get-parameter --name /aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64 --query Parameter.Value --output text)
echo "vpc=$VPC ami=$AMI"

echo "== 2. Security group: allow HTTP (80) in. No SSH port is opened"
SG=$(aws ec2 create-security-group --group-name lab-07-web-sg --description "Lab 07 web server: HTTP only" --vpc-id "$VPC" \
  --tag-specifications "ResourceType=security-group,Tags=[{$TAGS},{Key=Name,Value=lab-07-web-sg}]" --query GroupId --output text)
aws ec2 authorize-security-group-ingress --group-id "$SG" --protocol tcp --port 80 --cidr 0.0.0.0/0 >/dev/null

echo "== 3. Launch t3.micro with user data (IMDSv2 required)"
IID=$(aws ec2 run-instances --image-id "$AMI" --instance-type t3.micro --security-group-ids "$SG" \
  --user-data "file://$HERE/../src/user-data.sh" \
  --metadata-options HttpTokens=required,HttpEndpoint=enabled \
  --tag-specifications "ResourceType=instance,Tags=[{$TAGS},{Key=Lab,Value=07},{Key=Name,Value=lab-07-web-server}]" \
  --query 'Instances[0].InstanceId' --output text)
echo "$IID $SG" > "$HERE/.state"
aws ec2 wait instance-running --instance-ids "$IID"
IP=$(aws ec2 describe-instances --instance-ids "$IID" --query 'Reservations[0].Instances[0].PublicIpAddress' --output text)
echo "instance=$IID  public-ip=$IP"

echo "== 4. Wait for nginx to answer"
for i in $(seq 1 30); do
  CODE=$(curl -s -o /dev/null -m 5 -w '%{http_code}' "http://$IP/" || true)
  [ "$CODE" = "200" ] && break; sleep 10
done
echo "HTTP $CODE from http://$IP/"
curl -s "http://$IP/" | grep -E '<h1>|Instance ID|Availability Zone|Instance type' | sed -E 's/<[^>]+>//g'
