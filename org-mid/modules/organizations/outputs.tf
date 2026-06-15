# ==============================================================================
# Module: organizations
# File: outputs.tf
# Description: Exports outputs for org-mid organizations module.
# ==============================================================================

output "organization_arn" {
  value       = length(aws_organizations_organization.org) > 0 ? aws_organizations_organization.org[0].arn : null
  description = "The ARN of the AWS Organization."
}

output "security_ou_id" {
  value       = length(aws_organizations_organizational_unit.security) > 0 ? aws_organizations_organizational_unit.security[0].id : null
  description = "The ID of the Security OU."
}

output "infrastructure_ou_id" {
  value       = length(aws_organizations_organizational_unit.infrastructure) > 0 ? aws_organizations_organizational_unit.infrastructure[0].id : null
  description = "The ID of the Infrastructure OU."
}

output "workloads_ou_id" {
  value       = length(aws_organizations_organizational_unit.workloads) > 0 ? aws_organizations_organizational_unit.workloads[0].id : null
  description = "The ID of the Workloads OU."
}
