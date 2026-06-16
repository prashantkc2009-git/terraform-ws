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
  description = "Public subnet IDs for the ALB"
}

variable "listener_port" {
  type        = number
  description = "ALB listener port"
  default     = 80
}

variable "target_port" {
  type        = number
  description = "Target group port"
  default     = 80
}

variable "target_type" {
  type        = string
  description = "Target type (instance, ip, lambda)"
  default     = "ip"
}

variable "health_check_path" {
  type        = string
  description = "Health check path"
  default     = "/"
}
