output "secret_arns" {
  value       = { for k, s in aws_secretsmanager_secret.main : k => s.arn }
  description = "Map of secret names to ARNs"
}

output "secret_ids" {
  value       = { for k, s in aws_secretsmanager_secret.main : k => s.id }
  description = "Map of secret names to IDs"
}
