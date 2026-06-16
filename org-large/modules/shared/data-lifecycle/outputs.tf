output "backup_vault_arn" {
  value       = aws_backup_vault.main.arn
  description = "Backup vault ARN"
}

output "backup_plan_id" {
  value       = aws_backup_plan.main.id
  description = "Backup plan ID"
}
