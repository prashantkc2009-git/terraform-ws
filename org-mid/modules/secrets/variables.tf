# ==============================================================================
# Module: secrets
# File: variables.tf
# Description: Defines parameters for the org-mid secrets module.
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

variable "kms_key_arn" {
  type        = string
  description = "The ARN of the KMS Customer Managed Key for secrets encryption."
}
