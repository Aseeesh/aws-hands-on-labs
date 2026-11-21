import json

QUOTES = ["Build, measure, learn.", "Make it work, then make it fast.", "Automate the boring parts."]


def lambda_handler(event, context):
    """Handles GET /hello?name=... and GET /quote via API Gateway (Lambda proxy integration)."""
    path = event.get("path", "/")
    params = event.get("queryStringParameters") or {}
    if path.endswith("/quote"):
        body = {"quote": QUOTES[hash(context.aws_request_id) % len(QUOTES)]}
    else:
        body = {"message": f"Hello, {params.get('name', 'World')}!"}
    return {"statusCode": 200,
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps(body)}
