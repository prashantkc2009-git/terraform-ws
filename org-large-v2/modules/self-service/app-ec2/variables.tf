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
  description = "Subnet IDs — instances cycle through these by index for AZ distribution"
}

variable "source_sg_ids" {
  type        = list(string)
  description = "Security group IDs allowed to reach the app port"
  default     = []
}

variable "admin_cidr_blocks" {
  type        = list(string)
  description = "CIDR blocks allowed SSH access"
  default     = []
}

variable "instance_count" {
  type        = number
  description = "Number of EC2 instances"
  default     = 3
}

variable "ami" {
  type        = string
  description = "AMI ID (defaults to latest Amazon Linux 2023)"
  default     = null
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type"
  default     = "t3.micro"
}

variable "app_port" {
  type        = number
  description = "Application port"
  default     = 80
}

variable "user_data_base64" {
  type        = string
  description = "Base64-encoded user data script"
  default     = null
}
