# ==============================================================================
# Module: redis
# File: outputs.tf
# Description: Defines the outputs of the Redis ElastiCache module.
# ==============================================================================

output "primary_endpoint_address" {
  value       = aws_elasticache_replication_group.main.primary_endpoint_address
  description = "The address of the primary replication group endpoint."
}

output "reader_endpoint_address" {
  value       = aws_elasticache_replication_group.main.reader_endpoint_address
  description = "The address of the reader replication group endpoint."
}
