# ==============================================================================
# Module: security
# File: outputs.tf
# Description: Defines the outputs of the security module for downstream reference.
# ==============================================================================

output "kms_key_arn" {
  value       = aws_kms_key.main.arn
  description = "The ARN of the custom customer managed key."
}

output "kms_key_id" {
  value       = aws_kms_key.main.key_id
  description = "The key ID of the custom customer managed key."
}

output "alb_sg_id" {
  value       = aws_security_group.alb.id
  description = "The Security Group ID of the public Application Load Balancer."
}

output "app_sg_id" {
  value       = aws_security_group.app.id
  description = "The Security Group ID of the private application workloads."
}

output "data_sg_id" {
  value       = aws_security_group.data.id
  description = "The Security Group ID of the database and storage tier."
}

output "ssm_endpoint_sg_id" {
  value       = aws_security_group.ssm_endpoints.id
  description = "The Security Group ID of the private SSM endpoints."
}
