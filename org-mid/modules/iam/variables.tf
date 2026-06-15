# ==============================================================================
# Module: iam
# File: variables.tf
# Description: Defines parameters for the org-mid IAM module.
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

variable "github_org" {
  type        = string
  description = "GitHub organization name for OIDC configuration."
  default     = "company-mid-org"
}

variable "aws_region" {
  type        = string
  description = "The AWS region for resource ARN construction."
  default     = "us-east-1"
}
