variable "environment" {
  type        = string
  description = "Environment name"
}

variable "project_name" {
  type        = string
  description = "Project name"
  default     = "company-large"
}

variable "inspection_vpc_cidr" {
  type        = string
  description = "CIDR for the inspection VPC"
  default     = "10.250.0.0/16"
}

variable "availability_zones" {
  type        = list(string)
  description = "Availability zones"
  default     = ["us-east-1a", "us-east-1b"]
}
