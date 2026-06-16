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
  description = "Security Group ID for the database tier"
}

variable "kms_key_arn" {
  type        = string
  description = "KMS multi-region key ARN for encryption at rest"
}

variable "database_name" {
  type        = string
  description = "Database name"
  default     = "payments"
}

variable "master_username" {
  type        = string
  description = "Database master username"
  default     = "postgres"
}

variable "master_password" {
  type        = string
  description = "Database master password (use Secrets Manager in production)"
  sensitive   = true
}

variable "instance_class" {
  type        = string
  description = "RDS instance class"
  default     = "db.r7g.xlarge"
}

variable "instance_count" {
  type        = number
  description = "Number of DB instances in the cluster"
  default     = 2
}
