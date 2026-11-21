# Cleanup

Everything in this lab is free to keep, but to remove it (dependency order matters, so the script does it for you):

```bash
AWS_PROFILE=lab ./scripts/cleanup.sh
```
It disassociates and deletes the route tables, deletes the four subnets, detaches and deletes the internet gateway, then deletes the VPC.

Verify (expect `InvalidVpcID.NotFound`):
```bash
aws ec2 describe-vpcs --vpc-ids <vpc-id>
```
Console: VPC → Your VPCs → select `lab-12-vpc` → **Actions → Delete VPC**. The console's *Delete VPC* option also removes the attached subnets, route tables and gateway for you.
