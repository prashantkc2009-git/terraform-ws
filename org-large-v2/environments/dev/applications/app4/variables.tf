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
  default     = "app4"
  description = "Application name for resources"
}

variable "team" {
  type        = string
  default     = "app4-team"
  description = "Team owning the application"
}
