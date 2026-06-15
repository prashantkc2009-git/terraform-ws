# ==============================================================================
# Module: s3
# File: variables.tf
# Description: Defines parameters for the org-mid S3 module.
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
  description = "The ARN of the KMS Customer Managed Key for S3 bucket encryption."
}

variable "dr_region" {
  type        = string
  description = "Disaster Recovery region name for S3 replication."
  default     = "us-west-2"
}

variable "enable_replication" {
  type        = bool
  description = "Flag to enable Cross-Region Replication (CRR)."
  default     = false
}
