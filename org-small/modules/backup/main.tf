# ==============================================================================
# Module: backup
# File: main.tf
# Description: Provisions AWS Backup Vaults and Plans, targeting resources
#              with the tag Backup = true.
# ==============================================================================

resource "aws_backup_vault" "main" {
  name        = "${var.project_name}-${var.environment}-backup-vault"
  kms_key_arn = null # Uses default AWS backup service KMS key if null, or custom key

  tags = {
    Name        = "${var.project_name}-${var.environment}-backup-vault"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

resource "aws_backup_plan" "main" {
  name = "${var.project_name}-${var.environment}-backup-plan"

  rule {
    rule_name         = "daily-backup-rule"
    target_vault_name = aws_backup_vault.main.name
    schedule          = "cron(0 5 * * ? *)" # Daily at 5am UTC

    lifecycle {
      delete_after = var.retention_days
    }
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-backup-plan"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

resource "aws_backup_selection" "tagged_resources" {
  iam_role_arn = var.backup_role_arn
  name         = "${var.project_name}-${var.environment}-backup-selection"
  plan_id      = aws_backup_plan.main.id

  selection_tag {
    type  = "STRINGEQUALS"
    key   = "Backup"
    value = "true"
  }
}
