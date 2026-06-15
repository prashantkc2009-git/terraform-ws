# ==============================================================================
# Module: networking
# File: variables.tf
# Description: Defines all parameters for the core VPC infrastructure. All
#              variables include detailed descriptions and default values.
# ==============================================================================

variable "environment" {
  type        = string
  description = "The deployment environment name (e.g., dev, staging, prod)."
  default     = "dev"
}

variable "project_name" {
  type        = string
  description = "The name of the project to prefix or tag resources with."
  default     = "company-small"
}

variable "vpc_cidr" {
  type        = string
  description = "The CIDR block for the custom VPC."
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  type        = list(string)
  description = "A list of availability zones to deploy the subnets across."
  default     = ["us-east-1a", "us-east-1b"]
}

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "CIDR blocks for the public subnet tier (typically hosting ALBs and NAT GWs)."
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  type        = list(string)
  description = "CIDR blocks for the private subnet tier (hosting EC2, ASG, and EKS nodes). Styled as /22 to prevent EKS IP exhaustion."
  default     = ["10.0.8.0/22", "10.0.12.0/22"]
}

variable "data_subnet_cidrs" {
  type        = list(string)
  description = "CIDR blocks for the data subnet tier (hosting RDS, ElastiCache, and EFS mount targets)."
  default     = ["10.0.21.0/24", "10.0.22.0/24"]
}

variable "enable_nat_gateway" {
  type        = bool
  description = "Flag to enable NAT gateways for outbound private subnet routing."
  default     = true
}

variable "single_nat_gateway" {
  type        = bool
  description = "Flag to use a single NAT Gateway (for dev/staging cost saving) vs. one per AZ."
  default     = true
}

variable "domain_name" {
  type        = string
  description = "The root domain name managed within Route 53."
  default     = "company-small.io"
}
