variable "system" {
  type        = string
  description = "System or project identifier"
  default     = "company-large"
}

variable "environment" {
  type        = string
  description = "Environment name (e.g. prod, staging, dev)"
}

variable "team" {
  type        = string
  description = "Team responsible for the resource"
  default     = "platform-eng"
}

variable "cost_center" {
  type        = string
  description = "Cost center code for chargeback"
  default     = "CC-0000"
}

variable "module_name" {
  type        = string
  description = "Name of the module creating the resource"
}
