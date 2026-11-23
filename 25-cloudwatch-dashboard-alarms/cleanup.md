# Cleanup - Lab 25

```bash
AWS_PROFILE=lab ./scripts/cleanup.sh
```
Deletes both alarms and the dashboard. Console: CloudWatch → Alarms → select both → **Actions → Delete**; Dashboards → `lab-25-overview` → **Actions → Delete dashboard**.

Verify:
```bash
aws cloudwatch describe-alarms --alarm-name-prefix lab-25-    # empty list
aws cloudwatch list-dashboards --dashboard-name-prefix lab-25-  # empty list
```
Note: deleting Lab 19 first would make the "stopped" alarm fire, because the function no longer runs.
