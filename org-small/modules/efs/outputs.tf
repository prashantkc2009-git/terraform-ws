# ==============================================================================
# Module: efs
# File: outputs.tf
# Description: Defines the outputs of the EFS filesystem module.
# ==============================================================================

output "efs_id" {
  value       = aws_efs_file_system.main.id
  description = "The ID of the EFS filesystem."
}

output "efs_dns_name" {
  value       = aws_efs_file_system.main.dns_name
  description = "The DNS name of the EFS filesystem."
}
