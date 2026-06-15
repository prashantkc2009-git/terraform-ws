# ==============================================================================
# Environment: dev
# File: outputs.tf
# Description: Root level outputs for Dev environment.
# ==============================================================================

output "vpc_id" {
  value       = module.networking.vpc_id
  description = "The ID of the VPC."
}

output "public_subnet_ids" {
  value       = module.networking.public_subnet_ids
  description = "List of public subnet IDs."
}

output "private_subnet_ids" {
  value       = module.networking.private_subnet_ids
  description = "List of private subnet IDs."
}

output "kms_key_arn" {
  value       = module.security.kms_key_arn
  description = "The custom customer managed key ARN."
}

output "github_actions_role_arn" {
  value       = module.iam.github_actions_role_arn
  description = "GitHub Actions deployment IAM role ARN."
}

# ------------------------------------------------------------------------------
# COMPUTE LAYER OUTPUTS
# ------------------------------------------------------------------------------

# Workload A (Legacy Monolith)
output "ec2_legacy_active_instance_id" {
  value       = module.ec2_legacy.active_instance_id
  description = "The instance ID of the active EC2 legacy monolith."
}

output "ec2_legacy_active_private_ip" {
  value       = module.ec2_legacy.active_instance_private_ip
  description = "The private IP address of the active EC2 legacy monolith."
}

# Workload B (ASG API)
output "asg_api_alb_dns_name" {
  value       = module.asg_api.alb_dns_name
  description = "The DNS name of the API Application Load Balancer."
}

output "asg_api_fqdn" {
  value       = module.asg_api.api_fqdn
  description = "The FQDN of the API endpoint."
}

# Workload C (EKS Cluster)
output "eks_cluster_id" {
  value       = module.eks.cluster_id
  description = "The name of the EKS cluster."
}

output "eks_cluster_endpoint" {
  value       = module.eks.cluster_endpoint
  description = "The Kubernetes API server endpoint URL."
}

# Data Stores & Storage Outputs
output "rds_endpoint" {
  value       = module.rds.db_instance_endpoint
  description = "The RDS PostgreSQL connection endpoint."
}

output "redis_endpoint" {
  value       = module.redis.primary_endpoint_address
  description = "The Redis primary connection endpoint."
}

output "s3_bucket_arn" {
  value       = module.s3.bucket_arn
  description = "The ARN of the assets S3 bucket."
}

output "efs_id" {
  value       = module.efs.efs_id
  description = "The ID of the EFS shared filesystem."
}

output "db_credentials_secret_arn" {
  value       = module.secrets.db_credentials_secret_arn
  description = "The Secrets Manager ARN for database credentials."
}


