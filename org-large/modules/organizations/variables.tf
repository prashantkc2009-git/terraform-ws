variable "environment" {
  type        = string
  description = "Environment name (e.g. prod, staging, dev)"
}

variable "enable_scp" {
  type        = bool
  description = "Enable Service Control Policies"
  default     = true
}
