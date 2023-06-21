output "sqs_url" {
  value = module.queue.queue_url
}

output "producer_lambda_host" {
  value = local.producer_host
}

output "consumer_lambda_host" {
  value = local.consumer_host
}
