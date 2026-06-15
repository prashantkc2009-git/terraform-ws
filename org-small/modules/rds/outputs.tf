# ==============================================================================
# Module: rds
# File: outputs.tf
# Description: Defines the outputs of the RDS PostgreSQL database module.
# ==============================================================================

output "db_instance_endpoint" {
  value       = aws_db_instance.postgres.endpoint
  description = "The connection endpoint for the RDS database."
}

output "db_instance_address" {
  value       = aws_db_instance.postgres.address
  description = "The address of the RDS database."
}

output "db_instance_port" {
  value       = aws_db_instance.postgres.port
  description = "The connection port for the RDS database."
}

output "db_instance_username" {
  value       = aws_db_instance.postgres.username
  description = "The master username for the database."
}

output "db_instance_password" {
  value       = aws_db_instance.postgres.password
  sensitive   = true
  description = "The generated password for the database master user."
}
