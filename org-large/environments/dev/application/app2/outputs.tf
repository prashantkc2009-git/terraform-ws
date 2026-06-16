output "alb_dns_name" {
  value       = module.alb.alb_dns_name
  description = "App2 ALB DNS name"
}

output "dynamodb_table_arn" {
  value       = module.dynamodb.table_arn
  description = "App2 DynamoDB table ARN"
}

output "sqs_queue_url" {
  value       = module.sqs.queue_url
  description = "App2 SQS queue URL"
}

output "s3_bucket_id" {
  value       = module.s3.bucket_id
  description = "App2 S3 bucket ID"
}

output "eks_cluster_name" {
  value       = local.eks_cluster
  description = "Shared EKS cluster consumed by app2"
}
