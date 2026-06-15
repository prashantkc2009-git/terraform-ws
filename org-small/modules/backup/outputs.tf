# ==============================================================================
# Module: backup
# File: outputs.tf
# Description: Defines the outputs of the AWS Backup module.
# ==============================================================================

output "backup_vault_arn" {
  value       = aws_backup_vault.main.arn
  description = "The ARN of the backup vault."
}

output "backup_plan_arn" {
  value       = aws_backup_plan.main.arn
  description = "The ARN of the backup plan."
}
