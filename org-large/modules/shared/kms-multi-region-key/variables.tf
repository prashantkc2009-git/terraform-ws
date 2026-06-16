variable "environment" {
  type        = string
  description = "Environment name (e.g. prod, staging, dev)"
}

variable "project_name" {
  type        = string
  description = "Project name"
  default     = "company-large"
}

variable "key_policy" {
  type        = string
  description = "Optional custom KMS key policy JSON"
  default     = null
}
