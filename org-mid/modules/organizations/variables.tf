# ==============================================================================
# Module: organizations
# File: variables.tf
# Description: Defines parameters for the AWS Organization baseline.
# ==============================================================================

variable "environment" {
  type        = string
  description = "The deployment environment name (e.g., dev, staging, prod)."
}

variable "project_name" {
  type        = string
  description = "The name of the project."
  default     = "company-mid"
}

variable "enable_scp" {
  type        = bool
  description = "Flag to enable Service Control Policies (SCPs)."
  default     = false
}
