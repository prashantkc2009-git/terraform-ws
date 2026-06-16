output "vpc_id" {
  value       = module.vpc_base.vpc_id
  description = "Workload VPC ID"
}

output "private_subnet_ids" {
  value       = module.vpc_base.private_subnet_ids
  description = "Private subnet IDs"
}

output "data_subnet_ids" {
  value       = module.vpc_base.data_subnet_ids
  description = "Data subnet IDs"
}

output "eks_cluster_name" {
  value       = module.eks_cluster_blueprint.eks_cluster_name
  description = "EKS Cluster Name"
}

output "eks_cluster_endpoint" {
  value       = module.eks_cluster_blueprint.eks_cluster_endpoint
  description = "EKS Cluster Endpoint"
}

output "db_cluster_endpoint" {
  value       = module.aurora_global_database.db_cluster_endpoint
  description = "Database cluster writer endpoint"
}

output "kms_key_arn" {
  value       = module.kms.kms_key_arn
  description = "KMS Multi-Region Key ARN"
}

output "log_archive_bucket_arn" {
  value       = module.observability.log_archive_bucket_arn
  description = "Log Archive S3 Bucket ARN"
}

output "state_bucket_id" {
  value       = module.state_backend.state_bucket_id
  description = "Terraform State S3 Bucket ID"
}

output "dynamodb_lock_table_name" {
  value       = module.state_backend.dynamodb_lock_table_name
  description = "DynamoDB state lock table name"
}
