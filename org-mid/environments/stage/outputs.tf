# ==============================================================================
# Environment: stage
# File: outputs.tf
# Description: Exports resource details from the Staging environment stack.
# ==============================================================================

output "vpc_id" {
  value       = module.networking.vpc_id
  description = "The ID of the Staging VPC."
}

output "kms_key_arn" {
  value       = module.security.kms_key_arn
  description = "The ARN of the KMS Key used to encrypt state, S3, and secrets."
}

output "app_logs_bucket_arn" {
  value       = module.s3.app_logs_bucket_arn
  description = "The ARN of the central logs S3 bucket."
}

output "db_secret_arn" {
  value       = module.secrets.db_secret_arn
  description = "The ARN of the database credentials secret."
}

output "eks_node_instance_profile_name" {
  value       = module.iam.eks_node_instance_profile_name
  description = "The name of the IAM instance profile configured for worker nodes."
}
