# ==============================================================================
# Module: iam
# File: outputs.tf
# Description: Exports outputs for org-mid iam module.
# ==============================================================================

output "eks_cluster_role_arn" {
  value       = aws_iam_role.eks_cluster.arn
  description = "The ARN of the EKS Cluster execution role."
}

output "eks_node_role_arn" {
  value       = aws_iam_role.eks_node.arn
  description = "The ARN of the EKS Worker node execution role."
}

output "eks_node_instance_profile_name" {
  value       = aws_iam_instance_profile.eks_node.name
  description = "The name of the EKS node instance profile."
}

output "github_actions_role_arn" {
  value       = aws_iam_role.github_actions.arn
  description = "The ARN of the GitHub Actions OIDC deployment role."
}

output "github_oidc_provider_arn" {
  value       = aws_iam_openid_connect_provider.github.arn
  description = "The ARN of the GitHub OIDC identity provider."
}
