import json
from datetime import datetime, timezone


def lambda_handler(event, context):
    """Runs on a schedule. EventBridge passes the rule's event; we log when and why we ran."""
    now = datetime.now(timezone.utc).isoformat(timespec="seconds")
    print(json.dumps({"job": "lab-19-heartbeat", "ran_at": now,
                      "triggered_by": event.get("source", "manual"),
                      "rule": (event.get("resources") or ["n/a"])[0].split("/")[-1]}))
    return {"ok": True, "ran_at": now}
