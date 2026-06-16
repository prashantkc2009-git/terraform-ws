variable "environment" {
  type        = string
  description = "Environment name"
  default     = "dev"
}

variable "primary_region" {
  type        = string
  description = "Primary AWS region"
  default     = "us-east-1"
}
