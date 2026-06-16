variable "environment" {
  type        = string
  description = "Environment name (e.g. prod, staging, dev)"
}

variable "project_name" {
  type        = string
  description = "Project name"
  default     = "company-large"
}

variable "scope" {
  type        = string
  description = "WAF scope (REGIONAL or CLOUDFRONT)"
  default     = "REGIONAL"
}
