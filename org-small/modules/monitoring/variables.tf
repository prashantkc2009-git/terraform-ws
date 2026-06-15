# ==============================================================================
# Module: monitoring
# File: variables.tf
# Description: Defines the input variables for the CloudWatch monitoring module.
# ==============================================================================

variable "project_name" {
  type        = string
  description = "The name of the project."
}

variable "environment" {
  type        = string
  description = "The deployment environment (e.g. dev, staging, prod)."
}

variable "asg_name" {
  type        = string
  description = "The name of the API Auto Scaling Group to monitor."
  default     = ""
}

variable "db_instance_id" {
  type        = string
  description = "The database instance identifier to monitor."
  default     = ""
}
