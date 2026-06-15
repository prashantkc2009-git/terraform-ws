# ==============================================================================
# Module: rds
# File: variables.tf
# Description: Defines the input variables for the RDS PostgreSQL database module.
# ==============================================================================

variable "project_name" {
  type        = string
  description = "The name of the project."
}

variable "environment" {
  type        = string
  description = "The deployment environment (e.g. dev, staging, prod)."
}

variable "vpc_id" {
  type        = string
  description = "The ID of the VPC."
}

variable "data_subnet_ids" {
  type        = list(string)
  description = "List of data subnet IDs where the RDS subnet group will map."
}

variable "data_sg_id" {
  type        = string
  description = "The security group ID of the database and storage tier."
}

variable "kms_key_arn" {
  type        = string
  description = "The KMS key ARN for RDS storage encryption."
}

variable "instance_class" {
  type        = string
  description = "The instance class for the RDS database."
  default     = "db.t3.micro"
}

variable "multi_az" {
  type        = bool
  description = "Whether to provision the RDS database as Multi-AZ."
  default     = false
}

variable "allocated_storage" {
  type        = number
  description = "Allocated storage in GB."
  default     = 20
}

variable "database_name" {
  type        = string
  description = "The database name."
  default     = "monolith"
}

variable "master_username" {
  type        = string
  description = "Username for the database administrator."
  default     = "dbadmin"
}
