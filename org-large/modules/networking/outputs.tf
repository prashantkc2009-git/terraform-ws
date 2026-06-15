output "vpc_id" {
  value       = aws_vpc.workload.id
  description = "ID of the workload VPC"
}

output "private_subnet_ids" {
  value       = aws_subnet.private[*].id
  description = "IDs of the private subnets"
}

output "data_subnet_ids" {
  value       = aws_subnet.data[*].id
  description = "IDs of the data subnets"
}

output "ingress_alb_sg_id" {
  value       = aws_security_group.ingress_alb.id
  description = "ID of the ingress ALB security group"
}

output "private_eks_sg_id" {
  value       = aws_security_group.private_eks.id
  description = "ID of the EKS security group"
}

output "data_tier_sg_id" {
  value       = aws_security_group.data_tier.id
  description = "ID of the data tier security group"
}

output "core_network_arn" {
  value       = aws_networkmanager_core_network.core.arn
  description = "ARN of the Cloud WAN Core Network"
}
