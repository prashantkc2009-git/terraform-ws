output "nlb_arn" {
  value       = aws_lb.main.arn
  description = "NLB ARN"
}

output "nlb_dns_name" {
  value       = aws_lb.main.dns_name
  description = "NLB DNS name"
}

output "nlb_zone_id" {
  value       = aws_lb.main.zone_id
  description = "NLB hosted zone ID"
}

output "target_group_arn" {
  value       = aws_lb_target_group.main.arn
  description = "Target group ARN"
}

output "nlb_sg_id" {
  value       = aws_security_group.nlb.id
  description = "NLB security group ID"
}
