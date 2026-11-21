# Cleanup

This instance bills by the hour while running (a `t3.micro` is roughly $0.01/hour, about $9/month). Delete it when you no longer need it:

```bash
AWS_PROFILE=lab ./scripts/cleanup.sh
```
It terminates the instance, waits for termination, then deletes the security group (the group can't be deleted while an instance still uses it).

Verify:
```bash
aws ec2 describe-instances --instance-ids <id> --query 'Reservations[0].Instances[0].State.Name'   # "terminated"
aws ec2 describe-security-groups --group-ids <sg>                                                  # InvalidGroup.NotFound
```
Console: EC2 → Instances → select → **Instance state → Terminate instance**; then EC2 → Security Groups → delete `lab-07-web-sg`.

To pause billing without deleting: **Instance state → Stop instance**. (Compute billing stops; the small EBS disk still bills, and the public IP changes when you start it again.)
