resource "aws_sagemaker_domain" "ml_domain" {
  domain_name = "${var.project_name}-${var.environment}-sagemaker-domain"
  auth_mode   = "IAM"
  vpc_id      = var.vpc_id
  subnet_ids  = var.subnet_ids

  default_user_settings {
    execution_role = var.execution_role_arn
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-sagemaker"
    Environment = var.environment
  }
}

resource "aws_sagemaker_user_profile" "default" {
  domain_id         = aws_sagemaker_domain.ml_domain.id
  user_profile_name = "${var.project_name}-${var.environment}-default-user"
}
