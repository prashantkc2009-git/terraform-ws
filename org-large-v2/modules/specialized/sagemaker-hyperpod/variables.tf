variable "environment" {
  type        = string
  description = "Environment name"
}

variable "project_name" {
  type        = string
  description = "Project name"
  default     = "company-large"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID"
}

variable "subnet_ids" {
  type        = list(string)
  description = "Subnet IDs for SageMaker"
}

variable "execution_role_arn" {
  type        = string
  description = "SageMaker execution role ARN"
}
