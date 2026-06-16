output "s3_bucket_id" {
  value       = module.s3_bucket.bucket_id
  description = "The name/ID of the S3 bucket created for App 4"
}

output "dynamodb_table_name" {
  value       = module.dynamodb_table.table_name
  description = "The name of the DynamoDB table created for App 4"
}

output "sqs_queue_id" {
  value       = module.sqs_queue.queue_id
  description = "The URL of the SQS queue created for App 4"
}

output "eks_node_group_arn" {
  value       = aws_eks_node_group.app4_nodes.arn
  description = "The ARN of the EKS node group created for App 4"
}

output "alb_dns_name" {
  value       = aws_lb.alb.dns_name
  description = "The DNS name of the Application Load Balancer for App 4"
}
