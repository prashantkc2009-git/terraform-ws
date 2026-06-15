# ==============================================================================
# Module: security
# File: variables.tf
# Description: Defines input parameters for security components including KMS keys
#              and baseline firewall configurations.
# ==============================================================================

variable "environment" {
  type        = string
  description = "The deployment environment name (e.g., dev, staging, prod)."
  default     = "dev"
}

variable "project_name" {
  type        = string
  description = "The name of the project to tag resources with."
  default     = "company-small"
}

variable "domain_name" {
  type        = string
  description = "The root domain name managed within Route 53."
  default     = "company-small.io"
}
