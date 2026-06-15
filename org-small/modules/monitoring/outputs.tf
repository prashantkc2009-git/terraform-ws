# ==============================================================================
# Module: monitoring
# File: outputs.tf
# Description: Defines the outputs of the CloudWatch monitoring module.
# ==============================================================================

output "dashboard_arn" {
  value       = aws_cloudwatch_dashboard.main.dashboard_arn
  description = "The ARN of the CloudWatch dashboard."
}
