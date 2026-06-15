# ==============================================================================
# Module: secrets
# File: main.tf
# Description: Implements AWS Secrets Manager resources.
# ==============================================================================

resource "aws_secretsmanager_secret" "db_secret" {
  name                    = "${var.project_name}-${var.environment}-db-creds"
  description             = "Database credentials for Aurora PostgreSQL"
  kms_key_id              = var.kms_key_arn
  recovery_window_in_days = var.environment != "prod" ? 0 : 30

  tags = {
    Name        = "${var.project_name}-${var.environment}-db-creds"
    Environment = var.environment
  }
}

resource "aws_secretsmanager_secret_version" "db_secret_val" {
  secret_id = aws_secretsmanager_secret.db_secret.id
  secret_string = jsonencode({
    username = "dbadmin"
    password = "SuperSecurePassword123!"
    engine   = "postgres"
    host     = "placeholder"
    port     = 5432
  })
}
