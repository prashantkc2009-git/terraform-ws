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

variable "vpc_cidr" {
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.11.0/24"]
}

variable "data_subnet_cidrs" {
  type        = list(string)
  default     = ["10.0.20.0/24", "10.0.21.0/24"]
}

variable "availability_zones" {
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "aurora_database_name" {
  type        = string
  default     = "payments"
}

variable "aurora_master_password" {
  type        = string
  sensitive   = true
  default     = "MockPasswordForValidationOnly123!"
}
