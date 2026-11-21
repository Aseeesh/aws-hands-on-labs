import json


def lambda_handler(event, context):
    """Greets the name passed in the event; defaults to 'World'."""
    name = (event or {}).get("name", "World")
    print(f"Greeting requested for: {name}")  # goes to CloudWatch Logs
    return {"message": f"Hello, {name}! Greetings from AWS Lambda.",
            "request_id": context.aws_request_id}
