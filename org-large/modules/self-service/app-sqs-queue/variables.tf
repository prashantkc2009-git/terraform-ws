variable "app_name" {
  type        = string
  description = "Application name"
}

variable "environment" {
  type        = string
  description = "Environment name"
}

variable "queue_name" {
  type        = string
  description = "Queue name (suffix)"
}

variable "delay_seconds" {
  type        = number
  description = "Delay in seconds"
  default     = 0
}

variable "max_message_size" {
  type        = number
  description = "Maximum message size in bytes"
  default     = 262144
}

variable "message_retention_seconds" {
  type        = number
  description = "Message retention in seconds"
  default     = 345600
}

variable "receive_wait_time_seconds" {
  type        = number
  description = "Receive wait time for long polling"
  default     = 0
}

variable "visibility_timeout_seconds" {
  type        = number
  description = "Visibility timeout in seconds"
  default     = 30
}

variable "fifo_queue" {
  type        = bool
  description = "Whether to create a FIFO queue"
  default     = false
}

variable "content_based_deduplication" {
  type        = bool
  description = "Enable content-based deduplication (FIFO only)"
  default     = false
}

variable "kms_key_id" {
  type        = string
  description = "KMS key ID for encryption"
  default     = null
}

variable "kms_data_key_reuse_period_seconds" {
  type        = number
  description = "KMS data key reuse period in seconds"
  default     = 300
}

variable "create_dlq" {
  type        = bool
  description = "Create a DLQ for this queue"
  default     = true
}

variable "dlq_arn" {
  type        = string
  description = "Existing DLQ ARN (if create_dlq is false)"
  default     = null
}

variable "dlq_message_retention_seconds" {
  type        = number
  description = "DLQ message retention in seconds"
  default     = 1209600
}

variable "max_receive_count" {
  type        = number
  description = "Max receive count before sending to DLQ"
  default     = 5
}
