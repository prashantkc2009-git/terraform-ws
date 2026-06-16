variable "environment" {
  type        = string
  description = "Environment name (e.g. prod, staging, dev)"
}

variable "project_name" {
  type        = string
  description = "Project name"
  default     = "company-large"
}

variable "state_bucket_prefix" {
  type        = string
  description = "Prefix for the state S3 bucket name"
  default     = "company-tfstate"
}
