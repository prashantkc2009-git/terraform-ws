variable "environment" {
  type        = string
  description = "Environment name"
  default     = "global"
}

variable "project_name" {
  type        = string
  description = "Project name"
  default     = "company-large"
}

variable "primary_region" {
  type        = string
  description = "Primary AWS region"
  default     = "us-east-1"
}

variable "enable_govcloud" {
  type        = bool
  description = "Enable GovCloud OU"
  default     = false
}
