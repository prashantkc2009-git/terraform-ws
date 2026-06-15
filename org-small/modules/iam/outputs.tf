# ==============================================================================
# Module: iam
# File: outputs.tf
# Description: Defines the outputs of the IAM module.
# ==============================================================================

output "ec2_legacy_role_arn" {
  value       = aws_iam_role.ec2_legacy.arn
  description = "The ARN of the EC2 Legacy instance IAM role."
}

output "ec2_legacy_profile_name" {
  value       = aws_iam_instance_profile.ec2_legacy.name
  description = "The name of the EC2 Legacy Instance Profile."
}

output "asg_api_role_arn" {
  value       = aws_iam_role.asg_api.arn
  description = "The ARN of the ASG API instance IAM role."
}

output "asg_api_profile_name" {
  value       = aws_iam_instance_profile.asg_api.name
  description = "The name of the ASG API Instance Profile."
}

output "eks_cluster_role_arn" {
  value       = aws_iam_role.eks_cluster.arn
  description = "The ARN of the EKS Cluster IAM role."
}

output "eks_node_role_arn" {
  value       = aws_iam_role.eks_node.arn
  description = "The ARN of the EKS worker nodes IAM role."
}

output "github_actions_role_arn" {
  value       = aws_iam_role.github_actions.arn
  description = "The ARN of the GitHub Actions OIDC deploy IAM role."
}

output "backup_role_arn" {
  value       = aws_iam_role.backup.arn
  description = "The ARN of the AWS Backup IAM role."
}
