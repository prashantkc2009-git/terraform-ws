# ==============================================================================
# Module: networking
# File: outputs.tf
# Description: Exports outputs for org-mid networking resources.
# ==============================================================================

output "vpc_id" {
  value       = aws_vpc.main.id
  description = "The ID of the custom VPC."
}

output "public_subnet_ids" {
  value       = aws_subnet.public[*].id
  description = "A list of public subnet IDs."
}

output "private_subnet_ids" {
  value       = aws_subnet.private[*].id
  description = "A list of private subnet IDs."
}

output "data_subnet_ids" {
  value       = aws_subnet.data[*].id
  description = "A list of data subnet IDs."
}

output "endpoint_subnet_ids" {
  value       = aws_subnet.endpoint[*].id
  description = "A list of endpoint subnet IDs."
}

output "tgw_subnet_ids" {
  value       = aws_subnet.tgw[*].id
  description = "A list of TGW subnet IDs."
}

output "private_hosted_zone_id" {
  value       = aws_route53_zone.private.id
  description = "The Route53 private hosted zone ID."
}
