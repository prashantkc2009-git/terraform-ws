# ==============================================================================
# Module: ec2-legacy
# File: variables.tf
# Description: Defines the input variables for the legacy EC2 monolith module.
# ==============================================================================

variable "project_name" {
  type        = string
  description = "The name of the project."
}

variable "environment" {
  type        = string
  description = "The deployment environment (e.g. dev, staging, prod)."
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "List of private subnet IDs where the instances will run."
}

variable "app_sg_id" {
  type        = string
  description = "The Security Group ID of the private application tier."
}

variable "kms_key_arn" {
  type        = string
  description = "The ARN of the custom customer managed KMS key for EBS encryption."
}

variable "iam_instance_profile_name" {
  type        = string
  description = "The name of the IAM instance profile for the EC2 instances."
}

variable "instance_type_active" {
  type        = string
  description = "The instance type of the active node."
  default     = "t3.nano"
}

variable "instance_type_standby" {
  type        = string
  description = "The instance type of the standby node."
  default     = "t3.small"
}

variable "create_standby" {
  type        = bool
  description = "Whether to create a standby pilot light instance."
  default     = false
}

variable "root_volume_size" {
  type        = number
  description = "Size of the root EBS volume in GB."
  default     = 50
}

variable "data_volume_size" {
  type        = number
  description = "Size of the secondary data EBS volume in GB."
  default     = 50
}
