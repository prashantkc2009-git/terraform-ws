output "queue_id" {
  value       = aws_sqs_queue.main.id
  description = "SQS Queue ID"
}

output "queue_arn" {
  value       = aws_sqs_queue.main.arn
  description = "SQS Queue ARN"
}

output "queue_url" {
  value       = aws_sqs_queue.main.url
  description = "SQS Queue URL"
}

output "dlq_arn" {
  value       = var.create_dlq ? aws_sqs_queue.dlq[0].arn : var.dlq_arn
  description = "DLQ ARN"
}
