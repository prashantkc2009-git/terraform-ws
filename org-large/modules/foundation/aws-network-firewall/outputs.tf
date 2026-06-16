output "inspection_vpc_id" {
  value       = aws_vpc.inspection.id
  description = "Inspection VPC ID"
}

output "firewall_arn" {
  value       = aws_networkfirewall_firewall.main.arn
  description = "Network Firewall ARN"
}

output "firewall_policy_arn" {
  value       = aws_networkfirewall_firewall_policy.main.arn
  description = "Network Firewall Policy ARN"
}
