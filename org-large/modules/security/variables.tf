variable "environment" {
  type        = string
  description = "Environment name (e.g. prod, staging, dev)"
}

variable "project_name" {
  type        = string
  description = "Project name"
  default     = "company-large"
}

variable "aws_region" {
  type        = string
  description = "AWS region"
  default     = "us-east-1"
}
