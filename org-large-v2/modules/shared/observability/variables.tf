variable "environment" {
  type        = string
  description = "Environment name (e.g. prod, staging, dev)"
}

variable "project_name" {
  type        = string
  description = "Project name"
  default     = "company-large"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID to enable Flow Logs for"
}
