output "vpc_id" {
  value       = module.networking.vpc_id
  description = "Workload VPC ID"
}

output "eks_cluster_name" {
  value       = module.compute.eks_cluster_name
  description = "EKS Cluster Name"
}

output "db_cluster_endpoint" {
  value       = module.database.db_cluster_endpoint
  description = "Database cluster writer endpoint"
}

output "dynamodb_table_arn" {
  value       = module.database.dynamodb_table_arn
  description = "DynamoDB Table ARN"
}

output "kms_key_arn" {
  value       = module.security.kms_key_arn
  description = "KMS Multi-Region Key ARN"
}

output "log_archive_bucket_arn" {
  value       = module.observability.log_archive_bucket_arn
  description = "Log Archive S3 Bucket ARN"
}
