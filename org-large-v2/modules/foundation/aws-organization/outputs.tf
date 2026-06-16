output "organization_arn" {
  value       = var.environment == "prod" ? aws_organizations_organization.org[0].arn : null
  description = "ARN of the organization"
}

output "organization_id" {
  value       = var.environment == "prod" ? aws_organizations_organization.org[0].id : null
  description = "ID of the organization"
}

output "security_ou_id" {
  value       = var.environment == "prod" ? aws_organizations_organizational_unit.security[0].id : null
  description = "ID of the Security OU"
}

output "core_infra_ou_id" {
  value       = var.environment == "prod" ? aws_organizations_organizational_unit.core_infra[0].id : null
  description = "ID of the Core Infra OU"
}

output "business_lobs_ou_id" {
  value       = var.environment == "prod" ? aws_organizations_organizational_unit.business_lobs[0].id : null
  description = "ID of the Business LOBs OU"
}

output "developer_boundary_policy_arn" {
  value       = aws_iam_policy.developer_boundary.arn
  description = "ARN of the Developer Policy Boundary"
}

output "root_scp_id" {
  value       = var.enable_scp && var.environment == "prod" ? aws_organizations_policy.enterprise_scp[0].id : null
  description = "ID of the root SCP"
}
