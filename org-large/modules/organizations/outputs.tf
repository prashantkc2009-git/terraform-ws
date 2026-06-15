output "organization_arn" {
  value       = var.environment == "prod" ? aws_organizations_organization.org[0].arn : ""
  description = "ARN of the organization"
}

output "security_ou_id" {
  value       = var.environment == "prod" ? aws_organizations_organizational_unit.security[0].id : ""
  description = "ID of the Security OU"
}

output "core_infra_ou_id" {
  value       = var.environment == "prod" ? aws_organizations_organizational_unit.core_infra[0].id : ""
  description = "ID of the Core Infra OU"
}

output "business_lobs_ou_id" {
  value       = var.environment == "prod" ? aws_organizations_organizational_unit.business_lobs[0].id : ""
  description = "ID of the Business LOBs OU"
}
