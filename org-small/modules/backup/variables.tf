# ==============================================================================
# Module: backup
# File: variables.tf
# Description: Defines the input variables for the AWS Backup module.
# ==============================================================================

variable "project_name" {
  type        = string
  description = "The name of the project."
}

variable "environment" {
  type        = string
  description = "The deployment environment (e.g. dev, staging, prod)."
}

variable "backup_role_arn" {
  type        = string
  description = "The ARN of the AWS Backup service role."
}

variable "retention_days" {
  type        = number
  description = "The number of days to retain backups."
  default     = 7
}
