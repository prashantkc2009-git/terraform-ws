variable "environment" {
  type        = string
  description = "Environment name"
}

variable "enable_scp" {
  type        = bool
  description = "Enable Service Control Policies"
  default     = true
}

variable "enable_govcloud" {
  type        = bool
  description = "Enable GovCloud OU for FedRAMP workloads"
  default     = false
}
