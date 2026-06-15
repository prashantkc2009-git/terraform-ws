# ==============================================================================
# Module: iam
# File: variables.tf
# Description: Defines input parameters for configuring IAM roles, instance
#              profiles, and OIDC providers.
# ==============================================================================

variable "environment" {
  type        = string
  description = "The deployment environment name (e.g., dev, staging, prod)."
  default     = "dev"
}

variable "project_name" {
  type        = string
  description = "The name of the project to tag resources with."
  default     = "company-small"
}

variable "github_repo" {
  type        = string
  description = "GitHub repository formatted as organization/repository for OIDC trust."
  default     = "company-small-org/terraform-ws"
}
