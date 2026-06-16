resource "aws_s3_bucket_lifecycle_configuration" "log_archive_transition" {
  bucket = var.log_archive_bucket_id

  rule {
    id     = "transition-to-glacier"
    status = "Enabled"

    transition {
      days          = var.log_transition_days
      storage_class = "GLACIER"
    }

    expiration {
      days = var.log_expiration_days
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "backup_transition" {
  bucket = var.backup_bucket_id

  rule {
    id     = "backup-lifecycle"
    status = "Enabled"

    transition {
      days          = var.backup_transition_days
      storage_class = "DEEP_ARCHIVE"
    }

    expiration {
      days = var.backup_expiration_days
    }
  }
}

resource "aws_backup_vault" "main" {
  name        = "${var.project_name}-${var.environment}-backup-vault"
  kms_key_arn = var.kms_key_arn

  tags = {
    Name        = "${var.project_name}-${var.environment}-backup-vault"
    Environment = var.environment
  }
}

resource "aws_backup_plan" "main" {
  name = "${var.project_name}-${var.environment}-backup-plan"

  rule {
    rule_name         = "daily-backup"
    target_vault_name = aws_backup_vault.main.name
    schedule          = "cron(0 5 * * ? *)"

    lifecycle {
      delete_after = var.backup_retention_days
    }
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-backup-plan"
    Environment = var.environment
  }
}

resource "aws_backup_selection" "main" {
  name         = "${var.project_name}-${var.environment}-backup-selection"
  plan_id      = aws_backup_plan.main.id
  resources    = var.backup_resource_arns
}
