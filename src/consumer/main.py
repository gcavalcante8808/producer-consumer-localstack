import os
import json


def lambda_handler(event, context):
    print(event)

    return {
        "statusCode": 204,
        "headers": {
            "Content-Type": "application/json"
        },
        "body": {}
    }
