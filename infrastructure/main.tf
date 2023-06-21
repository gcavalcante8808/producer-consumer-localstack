locals {
  producer_host = regex("^(?:(?P<scheme>[^:/?#]+):)?(?://(?P<host>[^/?:#]*))?", module.producer.lambda_function_url).host
  consumer_host = regex("^(?:(?P<scheme>[^:/?#]+):)?(?://(?P<host>[^/?:#]*))?", module.consumer.lambda_function_url).host
}

data aws_iam_policy_document "allow_to_publish_on_queue" {
  statement {
    effect  = "Allow"
    actions = [
      "sqs:SendMessage",
      "sqs:SendMessageBatch",
      "sqs:ChangeMessageVisibility",
      "sqs:ChangeMessageVisibilityBatch"
    ]
    resources = [module.queue.queue_arn]
  }
}

data aws_iam_policy_document "allow_to_process_message_from_queue" {
  statement {
    effect  = "Allow"
    actions = [
      "sqs:ReceiveMessage",
      "sqs:DeleteMessage",
      "sqs:DeleteMessageBatch",
      "sqs:ChangeMessageVisibilityBatch",
      "sqs:ChangeMessageVisibility",
      "sqs:GetQueueAttributes"
    ]
    resources = [module.queue.queue_arn]
  }
}

module "cron" {
  source = "terraform-aws-modules/eventbridge/aws"

  create_bus = false

  rules = {
    crons = {
      description         = "Trigger for a Lambda"
      schedule_expression = "rate(60 minutes)"
    }
  }

  targets = {
    crons = [
      {
        name  = "trigger-producer-every-hour"
        arn   = module.producer.lambda_function_arn
        input = jsonencode({ "job" : "cron-by-rate" })
      }
    ]
  }
}

module "producer" {
  source = "terraform-aws-modules/lambda/aws"

  function_name = "producer"
  description   = "Do something and publish the result in a queue."
  handler       = "main.lambda_handler"
  runtime       = "python3.9"
  publish       = true

  create_lambda_function_url = true

  timeout = 10

  environment_variables = {
    SERVER_URL = "https://httpbin.org/json"
    SQS_URL    = module.queue.queue_url
  }

  attach_policy_json = true
  number_of_policies = 1
  policy_json        = data.aws_iam_policy_document.allow_to_publish_on_queue.json

  allowed_triggers = {
    RunEveryMinute = {
      principal  = "events.amazonaws.com"
      source_arn = module.cron.eventbridge_role_arn
    }
  }
  source_path = "../src/producer"
}

module "queue" {
  source = "terraform-aws-modules/sqs/aws"

  name = "example"

  create_dlq     = true
  redrive_policy = {
    maxReceiveCount = 10
  }

  tags = {
    Environment = "dev"
  }
}


module "consumer" {
  source = "terraform-aws-modules/lambda/aws"

  function_name = "consumer"
  description   = "Invoked when the queue has new messages!"
  handler       = "main.lambda_handler"
  runtime       = "python3.9"
  publish       = true

  create_lambda_function_url = true

  attach_policy_json = true
  number_of_policies = 1
  policy_json        = data.aws_iam_policy_document.allow_to_process_message_from_queue.json

  timeout              = 10
  event_source_mapping = {
    sqs = {
      event_source_arn = module.queue.queue_arn
      scaling_config   = {
        maximum_concurrency = 20
      }
    }
  }
  source_path = "../src/consumer"
}

resource "local_file" "justfile" {
  filename = "justfile"
  content = templatefile("templates/justfile.tftpl", {consumer_host = local.consumer_host, producer_host = local.producer_host})
}
