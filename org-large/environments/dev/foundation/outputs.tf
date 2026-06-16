output "inspection_vpc_id" {
  value       = module.network_firewall.inspection_vpc_id
  description = "Inspection VPC ID"
}

output "firewall_arn" {
  value       = module.network_firewall.firewall_arn
  description = "Network Firewall ARN"
}
