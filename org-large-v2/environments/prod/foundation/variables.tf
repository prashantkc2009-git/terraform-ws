variable "environment" {
  type        = string
  default     = "prod"
}

variable "project_name" {
  type        = string
  default     = "company-large"
}

variable "primary_region" {
  type        = string
  default     = "us-east-1"
}

variable "availability_zones" {
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}
