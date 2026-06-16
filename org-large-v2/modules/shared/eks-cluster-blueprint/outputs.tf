output "eks_cluster_name" {
  value       = aws_eks_cluster.main.name
  description = "EKS Cluster Name"
}

output "eks_cluster_endpoint" {
  value       = aws_eks_cluster.main.endpoint
  description = "EKS Cluster Endpoint"
}

output "eks_cluster_certificate_authority_data" {
  value       = aws_eks_cluster.main.certificate_authority[0].data
  description = "EKS Cluster CA Certificate Data"
}

output "eks_cluster_arn" {
  value       = aws_eks_cluster.main.arn
  description = "EKS Cluster ARN"
}

output "eks_node_role_arn" {
  value       = aws_iam_role.eks_nodes.arn
  description = "EKS Node IAM Role ARN"
}
