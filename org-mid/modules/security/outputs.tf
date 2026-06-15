# ==============================================================================
# Module: security
# File: outputs.tf
# Description: Exports outputs for org-mid security module.
# ==============================================================================

output "kms_key_arn" {
  value       = aws_kms_key.main.arn
  description = "The ARN of the main Customer Managed Key."
}

output "kms_key_id" {
  value       = aws_kms_key.main.key_id
  description = "The ID of the main Customer Managed Key."
}

output "edge_sg_id" {
  value       = aws_security_group.edge.id
  description = "The ID of the edge security group."
}

output "app_sg_id" {
  value       = aws_security_group.app.id
  description = "The ID of the application/compute security group."
}

output "data_sg_id" {
  value       = aws_security_group.data.id
  description = "The ID of the database/data store security group."
}

output "waf_web_acl_arn" {
  value       = aws_wafv2_web_acl.main.arn
  description = "The ARN of the regional WAF Web ACL."
}
