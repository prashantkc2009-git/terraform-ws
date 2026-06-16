variable "environment" {
  type        = string
  description = "Environment name (e.g. prod, staging, dev)"
}

variable "project_name" {
  type        = string
  description = "Project name"
  default     = "company-large"
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
  description = "KMS key ARN for encryption at rest"
}

variable "kafka_version" {
  type        = string
  description = "Kafka version"
  default     = "3.4.0"
}

variable "broker_instance_type" {
  type        = string
  description = "MSK broker instance type"
  default     = "kafka.m5.large"
}

variable "broker_volume_size" {
  type        = number
  description = "EBS volume size per broker in GB"
  default     = 100
}
