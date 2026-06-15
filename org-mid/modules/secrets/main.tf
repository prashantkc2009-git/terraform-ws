# ==============================================================================
# Module: secrets
# File: main.tf
# Description: Implements AWS Secrets Manager resources with auto-generated credentials.
# ==============================================================================

terraform {
  required_providers {
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

resource "random_password" "db_master" {
  length           = 24
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

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
    password = random_password.db_master.result
    engine   = "postgres"
    host     = "placeholder" # Update with actual RDS/Aurora endpoint after compute module creation
    port     = 5432
  })
}
