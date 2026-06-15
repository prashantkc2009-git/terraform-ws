output "db_cluster_endpoint" {
  value       = aws_rds_cluster.primary.endpoint
  description = "Database cluster writer endpoint"
}

output "db_cluster_reader_endpoint" {
  value       = aws_rds_cluster.primary.reader_endpoint
  description = "Database cluster reader endpoint"
}

output "dynamodb_table_arn" {
  value       = aws_dynamodb_table.sessions.arn
  description = "DynamoDB Table ARN"
}

output "msk_cluster_arn" {
  value       = aws_msk_cluster.event_stream.arn
  description = "MSK Kafka Cluster ARN"
}
