variable "environment" {
  type        = string
  default     = "dev"
}

variable "primary_region" {
  type        = string
  default     = "us-east-1"
}

variable "app_name" {
  type        = string
  description = "Application name for self-service resources"
  default     = "example-app"
}

variable "team" {
  type        = string
  description = "Team owning the application"
  default     = "example-team"
}
