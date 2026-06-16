output "organization_id" {
  value       = module.aws_organization.organization_id
  description = "Organization ID"
}

output "organization_arn" {
  value       = module.aws_organization.organization_arn
  description = "Organization ARN"
}

output "core_network_arn" {
  value       = module.aws_cloud_wan.core_network_arn
  description = "Cloud WAN Core Network ARN"
}

output "developer_boundary_policy_arn" {
  value       = module.aws_organization.developer_boundary_policy_arn
  description = "Developer IAM Boundary Policy ARN"
}

output "business_lobs_ou_id" {
  value       = module.aws_organization.business_lobs_ou_id
  description = "Business LOBs OU ID"
}

output "security_ou_id" {
  value       = module.aws_organization.security_ou_id
  description = "Security OU ID"
}
