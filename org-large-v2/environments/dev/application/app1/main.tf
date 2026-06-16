data "aws_ssm_parameter" "vpc_id" {
  name = "/company-large/${var.environment}/network/vpc_id"
}

data "aws_ssm_parameter" "public_subnet_ids" {
  name = "/company-large/${var.environment}/network/public_subnet_ids"
}

data "aws_ssm_parameter" "private_subnet_ids" {
  name = "/company-large/${var.environment}/network/private_subnet_ids"
}

data "aws_ssm_parameter" "kms_key_arn" {
  name = "/company-large/${var.environment}/security/kms_key_arn"
}

locals {
  vpc_id         = data.aws_ssm_parameter.vpc_id.value
  public_subnets = split(",", data.aws_ssm_parameter.public_subnet_ids.value)
  private_subnets = split(",", data.aws_ssm_parameter.private_subnet_ids.value)
  kms_key_arn    = data.aws_ssm_parameter.kms_key_arn.value
}

resource "aws_security_group" "app1_data" {
  name        = "app1-${var.environment}-data-sg"
  description = "App1 data tier SG"
  vpc_id      = local.vpc_id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [module.ec2.ec2_sg_id]
  }

  tags = {
    Name        = "app1-${var.environment}-data-sg"
    Environment = var.environment
    AppName     = "app1"
  }
}

module "aurora" {
  source          = "../../../../modules/shared/aurora-global-database"
  environment     = var.environment
  project_name    = "app1"
  vpc_id          = local.vpc_id
  data_subnet_ids = local.private_subnets
  data_tier_sg_id = aws_security_group.app1_data.id
  kms_key_arn     = local.kms_key_arn
  database_name   = "app1db"
  master_password = var.aurora_master_password
  instance_count  = 1
}

module "nlb" {
  source       = "../../../../modules/self-service/app-nlb"
  app_name     = "app1"
  environment  = var.environment
  vpc_id       = local.vpc_id
  subnet_ids   = local.public_subnets
  listener_port = 443
  target_port  = 80
}

module "ec2" {
  source         = "../../../../modules/self-service/app-ec2"
  app_name       = "app1"
  environment    = var.environment
  vpc_id         = local.vpc_id
  subnet_ids     = local.public_subnets
  source_sg_ids  = [module.nlb.nlb_sg_id]
  instance_count = 3
  instance_type  = var.instance_type
  user_data_base64 = filebase64("${path.module}/user_data.sh")
}

module "s3" {
  source      = "../../../../modules/self-service/app-s3-bucket"
  app_name    = "app1"
  environment = var.environment
  team        = "team-app1"
  bucket_suffix = "data"
}
