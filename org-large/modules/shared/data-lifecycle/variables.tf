variable "project_name" {
  type        = string
  description = "Project name"
  default     = "company-large"
}

variable "environment" {
  type        = string
  description = "Environment name"
}

variable "log_archive_bucket_id" {
  type        = string
  description = "Log archive S3 bucket ID"
}

variable "backup_bucket_id" {
  type        = string
  description = "Backup S3 bucket ID"
  default     = ""
}

variable "kms_key_arn" {
  type        = string
  description = "KMS key ARN for backup vault"
  default     = null
}

variable "log_transition_days" {
  type        = number
  description = "Days before transitioning logs to Glacier"
  default     = 90
}

variable "log_expiration_days" {
  type        = number
  description = "Days before expiring logs"
  default     = 2555
}

variable "backup_transition_days" {
  type        = number
  description = "Days before transitioning backups to Deep Archive"
  default     = 30
}

variable "backup_expiration_days" {
  type        = number
  description = "Days before expiring backups"
  default     = 365
}

variable "backup_retention_days" {
  type        = number
  description = "Days to retain backups"
  default     = 30
}

variable "backup_resource_arns" {
  type        = list(string)
  description = "ARNs of resources to back up"
  default     = []
}
