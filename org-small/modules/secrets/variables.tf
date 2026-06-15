# ==============================================================================
# Module: secrets
# File: variables.tf
# Description: Defines the input variables for the Secrets Manager module.
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
  description = "The KMS key ARN for Secrets Manager encryption."
}

variable "db_password" {
  type        = string
  sensitive   = true
  description = "The database administrator password to be stored securely."
}

variable "db_username" {
  type        = string
  description = "The database administrator username."
}
