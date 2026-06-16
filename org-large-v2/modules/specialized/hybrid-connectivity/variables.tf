variable "environment" {
  type        = string
  description = "Environment name"
}

variable "project_name" {
  type        = string
  description = "Project name"
  default     = "company-large"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID"
}

variable "on_prem_bgp_asn" {
  type        = number
  description = "BGP ASN for on-premises customer gateway"
  default     = 65000
}

variable "on_prem_ip_address" {
  type        = string
  description = "Public IP of on-premises VPN endpoint"
  default     = "203.0.113.12"
}

variable "enable_bare_metal" {
  type        = bool
  description = "Deploy EC2 Bare Metal instance for legacy workloads"
  default     = false
}

variable "bare_metal_ami" {
  type        = string
  description = "AMI for bare metal instance"
  default     = "ami-0c55b159cbfafe1f0"
}

variable "bare_metal_instance_type" {
  type        = string
  description = "EC2 instance type for bare metal"
  default     = "m7i-metal-24xl"
}

variable "subnet_id" {
  type        = string
  description = "Subnet ID for bare metal instance"
  default     = null
}
