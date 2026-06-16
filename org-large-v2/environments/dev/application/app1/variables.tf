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

variable "aurora_master_password" {
  type        = string
  description = "Aurora master password"
  sensitive   = true
  default     = "App1DevPassword123!"
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type"
  default     = "t3.micro"
}
