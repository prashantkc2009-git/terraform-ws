variable "environment" {
  type        = string
  default     = "dev"
  description = "Target environment"
}

variable "primary_region" {
  type        = string
  default     = "us-east-1"
  description = "Primary AWS region"
}

variable "app_name" {
  type        = string
  default     = "app3"
  description = "Application name for resources"
}

variable "team" {
  type        = string
  default     = "app3-team"
  description = "Team owning the application"
}

variable "aurora_master_password" {
  type        = string
  default     = "SuperSecretPassword123!"
  sensitive   = true
  description = "Master database password for Aurora"
}
