output "db_cluster_endpoint" {
  value       = aws_rds_cluster.primary.endpoint
  description = "Database cluster writer endpoint"
}

output "db_cluster_reader_endpoint" {
  value       = aws_rds_cluster.primary.reader_endpoint
  description = "Database cluster reader endpoint"
}

output "db_cluster_arn" {
  value       = aws_rds_cluster.primary.arn
  description = "Database cluster ARN"
}

output "global_cluster_id" {
  value       = aws_rds_global_cluster.global_db.id
  description = "Global cluster ID"
}
