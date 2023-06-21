import os
import json
import boto3
import requests


def lambda_handler(event, context):
    url = os.environ['SERVER_URL']
    sqs_url = os.environ['SQS_URL']
    endpoint_url = os.getenv('AWS_ENDPOINT_URL', 'https://sqs.us-east-1.amazonaws.com' )

    response = requests.get(url, headers={"Content-Type": "application/json"})
    response.raise_for_status()

    sqs = boto3.client("sqs", endpoint_url=endpoint_url)
    publish_response = sqs.send_message(
        QueueUrl=sqs_url,
        MessageBody=json.dumps(response.json())
    )

    return {
        "statusCode": 204,
        "headers": {
            "Content-Type": "application/json"
        },
        "body": {}
    }
