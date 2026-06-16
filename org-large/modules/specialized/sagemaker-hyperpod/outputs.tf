output "domain_id" {
  value       = aws_sagemaker_domain.ml_domain.id
  description = "SageMaker Domain ID"
}

output "domain_arn" {
  value       = aws_sagemaker_domain.ml_domain.arn
  description = "SageMaker Domain ARN"
}

output "user_profile_name" {
  value       = aws_sagemaker_user_profile.default.user_profile_name
  description = "Default SageMaker user profile name"
}
