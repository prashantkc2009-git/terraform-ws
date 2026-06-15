# ==============================================================================
# Module: asg-api
# File: outputs.tf
# Description: Defines the outputs of the auto-scaled API module (Workload B).
# ==============================================================================

output "alb_dns_name" {
  value       = aws_lb.api.dns_name
  description = "The DNS name of the Application Load Balancer."
}

output "alb_zone_id" {
  value       = aws_lb.api.zone_id
  description = "The canonical hosted zone ID of the load balancer."
}

output "asg_name" {
  value       = aws_autoscaling_group.api.name
  description = "The name of the Auto Scaling Group."
}

output "asg_arn" {
  value       = aws_autoscaling_group.api.arn
  description = "The ARN of the Auto Scaling Group."
}

output "api_fqdn" {
  value       = aws_route53_record.api.fqdn
  description = "The fully qualified domain name (FQDN) for the API."
}
