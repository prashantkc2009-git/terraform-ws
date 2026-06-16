output "oidc_provider_arn" {
  value       = aws_iam_openid_connect_provider.github.arn
  description = "GitHub OIDC Provider ARN"
}

output "oidc_provider_url" {
  value       = aws_iam_openid_connect_provider.github.url
  description = "GitHub OIDC Provider URL"
}

output "terraform_plan_role_arn" {
  value       = aws_iam_role.terraform_plan.arn
  description = "Terraform Plan IAM Role ARN"
}

output "terraform_apply_role_arn" {
  value       = var.enable_apply_role ? aws_iam_role.terraform_apply[0].arn : null
  description = "Terraform Apply IAM Role ARN"
}
