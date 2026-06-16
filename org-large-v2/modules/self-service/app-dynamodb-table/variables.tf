variable "app_name" {
  type        = string
  description = "Application name"
}

variable "environment" {
  type        = string
  description = "Environment name"
}

variable "table_name" {
  type        = string
  description = "DynamoDB table name (suffix)"
}

variable "billing_mode" {
  type        = string
  description = "Billing mode"
  default     = "PAY_PER_REQUEST"
}

variable "hash_key" {
  type        = string
  description = "Hash key attribute name"
}

variable "range_key" {
  type        = string
  description = "Range key attribute name"
  default     = null
}

variable "attributes" {
  type = list(object({
    name = string
    type = string
  }))
  description = "Attribute definitions"
}

variable "replica_regions" {
  type        = list(string)
  description = "Regions for global table replicas"
  default     = []
}

variable "kms_key_arn" {
  type        = string
  description = "KMS key ARN"
  default     = null
}

variable "enable_pitr" {
  type        = bool
  description = "Enable Point-in-Time Recovery"
  default     = true
}

variable "enable_stream" {
  type        = bool
  description = "Enable DynamoDB Streams"
  default     = true
}
