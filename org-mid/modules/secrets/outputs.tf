# ==============================================================================
# Module: secrets
# File: outputs.tf
# Description: Exports outputs for org-mid secrets module.
# ==============================================================================

output "db_secret_arn" {
  value       = aws_secretsmanager_secret.db_secret.arn
  description = "The ARN of the database credentials secret."
}

output "db_secret_id" {
  value       = aws_secretsmanager_secret.db_secret.id
  description = "The ID of the database credentials secret."
}
