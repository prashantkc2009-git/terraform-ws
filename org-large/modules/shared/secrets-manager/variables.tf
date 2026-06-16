variable "environment" {
  type        = string
  description = "Environment name (e.g. prod, staging, dev)"
}

variable "project_name" {
  type        = string
  description = "Project name"
  default     = "company-large"
}

variable "kms_key_arn" {
  type        = string
  description = "KMS key ARN for encryption"
  default     = null
}

variable "recovery_window_days" {
  type        = number
  description = "Recovery window for secret deletion"
  default     = 7
}

variable "secrets" {
  type = map(object({
    description     = optional(string)
    value           = optional(string, null)
    length          = optional(number, 24)
    special         = optional(bool, true)
    upper           = optional(bool, true)
    lower           = optional(bool, true)
    numeric         = optional(bool, true)
    enable_rotation = optional(bool, false)
    rotation_days   = optional(number, 14)
  }))
  description = "Map of secrets to create"
  default     = {}
}
