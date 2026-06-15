output "kms_key_arn" {
  value       = aws_kms_key.mrk_primary.arn
  description = "KMS Primary Multi-Region Key ARN"
}

output "kms_key_id" {
  value       = aws_kms_key.mrk_primary.key_id
  description = "KMS Primary Multi-Region Key ID"
}

output "developer_boundary_policy_arn" {
  value       = aws_iam_policy.developer_boundary.arn
  description = "ARN of the Developer Policy Boundary"
}

output "waf_web_acl_arn" {
  value       = aws_wafv2_web_acl.main.arn
  description = "ARN of the WAF Web ACL"
}
