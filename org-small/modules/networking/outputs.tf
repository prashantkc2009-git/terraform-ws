# ==============================================================================
# Module: networking
# File: outputs.tf
# Description: Declares standard output variables for reuse by other modules or
#              root deployments.
# ==============================================================================

output "vpc_id" {
  value       = aws_vpc.main.id
  description = "The ID of the VPC."
}

output "public_subnet_ids" {
  value       = aws_subnet.public[*].id
  description = "List of IDs of the public subnets."
}

output "private_subnet_ids" {
  value       = aws_subnet.private[*].id
  description = "List of IDs of the private subnets."
}

output "data_subnet_ids" {
  value       = aws_subnet.data[*].id
  description = "List of IDs of the data subnets."
}

output "route53_zone_id" {
  value       = aws_route53_zone.public.zone_id
  description = "The Route 53 zone ID."
}

output "acm_certificate_arn" {
  value       = aws_acm_certificate.cert.arn
  description = "The ARN of the ACM Certificate."
}
