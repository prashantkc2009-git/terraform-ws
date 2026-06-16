variable "environment" {
  type        = string
  default     = "dev"
}

variable "project_name" {
  type        = string
  default     = "company-large"
}

variable "primary_region" {
  type        = string
  default     = "us-east-1"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID"
}

variable "subnet_ids" {
  type        = list(string)
  description = "Subnet IDs for specialized workloads"
}

variable "execution_role_arn" {
  type        = string
  description = "SageMaker execution role ARN"
  default     = ""
}

variable "enable_bare_metal" {
  type        = bool
  default     = false
}

variable "bare_metal_subnet_id" {
  type        = string
  default     = null
}
