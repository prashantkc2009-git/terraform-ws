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
  description = "Subnet IDs for ECS tasks"
}

variable "security_group_ids" {
  type        = list(string)
  description = "Security group IDs for ECS tasks"
}

variable "container_name" {
  type        = string
  description = "Container name"
  default     = "app"
}

variable "container_image" {
  type        = string
  description = "Container image URI"
}

variable "container_port" {
  type        = number
  description = "Container port"
  default     = 8080
}

variable "cpu" {
  type        = string
  description = "Fargate CPU units"
  default     = "512"
}

variable "memory" {
  type        = string
  description = "Fargate memory MB"
  default     = "1024"
}

variable "desired_count" {
  type        = number
  description = "Desired task count"
  default     = 2
}

variable "health_check_path" {
  type        = string
  description = "Health check path"
  default     = "/health"
}

variable "alb_listener_arn" {
  type        = string
  description = "ALB listener ARN for routing"
  default     = null
}

variable "listener_rule_priority" {
  type        = number
  description = "Listener rule priority"
  default     = 100
}

variable "path_patterns" {
  type        = list(string)
  description = "Path patterns for ALB routing"
  default     = ["/*"]
}

variable "environment_variables" {
  type        = map(string)
  description = "Environment variables for the container"
  default     = {}
}

variable "permissions_boundary_arn" {
  type        = string
  description = "IAM permissions boundary ARN"
  default     = null
}
