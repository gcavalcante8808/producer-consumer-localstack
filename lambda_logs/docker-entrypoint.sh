#!/usr/bin/env bash

set -euxo pipefail

exec awslogs get /aws/lambda/"${AWS_LAMBDA_NAME}" ALL --watch --endpoint-url "${AWS_ENDPOINT_URL}"
