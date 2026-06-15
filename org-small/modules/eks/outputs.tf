# ==============================================================================
# Module: eks
# File: outputs.tf
# Description: Defines the outputs of the EKS module (Workload C).
# ==============================================================================

output "cluster_id" {
  value       = aws_eks_cluster.main.id
  description = "The name/ID of the EKS cluster."
}

output "cluster_arn" {
  value       = aws_eks_cluster.main.arn
  description = "The ARN of the EKS cluster."
}

output "cluster_endpoint" {
  value       = aws_eks_cluster.main.endpoint
  description = "The endpoint for your EKS Kubernetes API."
}

output "cluster_certificate_authority_data" {
  value       = aws_eks_cluster.main.certificate_authority[0].data
  description = "The base64 encoded certificate data required to communicate with your cluster."
}

output "on_demand_node_group_arn" {
  value       = aws_eks_node_group.on_demand.arn
  description = "The ARN of the on-demand managed node group."
}

output "spot_node_group_arn" {
  value       = var.enable_spot_nodes ? aws_eks_node_group.spot[0].arn : null
  description = "The ARN of the spot managed node group."
}
