# ==============================================================================
# Module: security
# File: variables.tf
# Description: Defines parameters for the org-mid security module.
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

variable "vpc_id" {
  type        = string
  description = "The ID of the custom VPC."
}

variable "vpc_cidr" {
  type        = string
  description = "The CIDR block of the VPC for internal traffic rules."
}

variable "kms_key_rotation_enabled" {
  type        = bool
  description = "Flag to enable KMS CMK automatic key rotation."
  default     = true
}
