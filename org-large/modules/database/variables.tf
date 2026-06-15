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
  description = "VPC ID"
}

variable "data_subnet_ids" {
  type        = list(string)
  description = "Subnet IDs for the database tier"
}

variable "data_tier_sg_id" {
  type        = string
  description = "Security Group ID for the database/cache tier"
}

variable "kms_key_arn" {
  type        = string
  description = "KMS multi-region key ARN for encryption at rest"
}
