# ==============================================================================
# Module: secrets
# File: outputs.tf
# Description: Defines the outputs of the Secrets Manager module.
# ==============================================================================

output "db_credentials_secret_arn" {
  value       = aws_secretsmanager_secret.db_credentials.arn
  description = "The ARN of the database credentials secret."
}
