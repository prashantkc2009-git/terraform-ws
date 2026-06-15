# ==============================================================================
# Module: s3
# File: variables.tf
# Description: Defines the input variables for the S3 bucket module.
# ==============================================================================

variable "project_name" {
  type        = string
  description = "The name of the project."
}

variable "environment" {
  type        = string
  description = "The deployment environment (e.g. dev, staging, prod)."
}

variable "kms_key_arn" {
  type        = string
  description = "The ARN of the KMS key for S3 bucket encryption."
}
