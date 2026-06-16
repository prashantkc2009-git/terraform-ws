variable "environment" {
  type        = string
  description = "Environment name (e.g. prod, staging, dev)"
}

variable "project_name" {
  type        = string
  description = "Project name"
  default     = "company-large"
}

variable "table_name" {
  type        = string
  description = "DynamoDB table name"
}

variable "billing_mode" {
  type        = string
  description = "Billing mode (PAY_PER_REQUEST or PROVISIONED)"
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
  description = "List of attribute definitions"
}

variable "replica_regions" {
  type        = list(string)
  description = "Regions for DynamoDB Global Table replicas"
  default     = []
}

variable "kms_key_arn" {
  type        = string
  description = "KMS key ARN for encryption"
  default     = null
}

variable "enable_pitr" {
  type        = bool
  description = "Enable Point-in-Time Recovery"
  default     = true
}
