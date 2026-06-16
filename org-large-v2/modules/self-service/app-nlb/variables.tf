variable "app_name" {
  type        = string
  description = "Application name"
}

variable "environment" {
  type        = string
  description = "Environment name"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID"
}

variable "subnet_ids" {
  type        = list(string)
  description = "Public subnet IDs for the NLB"
}

variable "listener_port" {
  type        = number
  description = "NLB listener port"
  default     = 443
}

variable "target_port" {
  type        = number
  description = "Target group port"
  default     = 80
}
