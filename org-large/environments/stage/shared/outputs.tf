output "vpc_id" {
  value       = module.vpc_base.vpc_id
}

output "eks_cluster_name" {
  value       = module.eks_cluster_blueprint.eks_cluster_name
}

output "db_cluster_endpoint" {
  value       = module.aurora_global_database.db_cluster_endpoint
}

output "kms_key_arn" {
  value       = module.kms.kms_key_arn
}

output "log_archive_bucket_arn" {
  value       = module.observability.log_archive_bucket_arn
}

output "state_bucket_id" {
  value       = module.state_backend.state_bucket_id
}
