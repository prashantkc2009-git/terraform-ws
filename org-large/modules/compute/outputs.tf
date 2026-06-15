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

output "sagemaker_domain_id" {
  value       = aws_sagemaker_domain.ml_domain.id
  description = "SageMaker Domain ID"
}

output "legacy_mainframe_connector_private_ip" {
  value       = aws_instance.legacy_mainframe_connector.private_ip
  description = "Private IP of the mainframe connector instance"
}
