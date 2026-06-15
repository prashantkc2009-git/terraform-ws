# ==============================================================================
# Module: efs
# File: variables.tf
# Description: Defines the input variables for the EFS shared filesystem module.
# ==============================================================================

variable "project_name" {
  type        = string
  description = "The name of the project."
}

variable "environment" {
  type        = string
  description = "The deployment environment (e.g. dev, staging, prod)."
}

variable "data_subnet_ids" {
  type        = list(string)
  description = "List of data subnet IDs where EFS mount targets will be provisioned."
}

variable "data_sg_id" {
  type        = string
  description = "The security group ID of the database and storage tier."
}

variable "kms_key_arn" {
  type        = string
  description = "The KMS key ARN for EFS filesystem encryption."
}
