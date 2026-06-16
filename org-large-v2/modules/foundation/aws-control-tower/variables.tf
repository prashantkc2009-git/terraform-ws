variable "root_ou_id" {
  type        = string
  description = "Root OU ID for Control Tower guardrails"
}

variable "enable_guardrails" {
  type        = bool
  description = "Enable mandatory Control Tower guardrails"
  default     = true
}
