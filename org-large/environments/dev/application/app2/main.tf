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

data "aws_ssm_parameter" "eks_cluster_name" {
  name = "/company-large/${var.environment}/eks/cluster_name"
}

data "aws_ssm_parameter" "eks_cluster_endpoint" {
  name = "/company-large/${var.environment}/eks/cluster_endpoint"
}

locals {
  vpc_id          = data.aws_ssm_parameter.vpc_id.value
  public_subnets  = split(",", data.aws_ssm_parameter.public_subnet_ids.value)
  private_subnets = split(",", data.aws_ssm_parameter.private_subnet_ids.value)
  kms_key_arn     = data.aws_ssm_parameter.kms_key_arn.value
  eks_cluster     = data.aws_ssm_parameter.eks_cluster_name.value
}

module "alb" {
  source       = "../../../../modules/self-service/app-alb"
  app_name     = "app2"
  environment  = var.environment
  vpc_id       = local.vpc_id
  subnet_ids   = local.public_subnets
  listener_port = 80
  target_port  = 80
  target_type  = "ip"
}

module "dynamodb" {
  source      = "../../../../modules/self-service/app-dynamodb-table"
  app_name    = "app2"
  environment = var.environment
  table_name  = "app2-sessions"
  hash_key    = "PK"
  attributes = [
    { name = "PK", type = "S" }
  ]
  kms_key_arn = local.kms_key_arn
}

module "sqs" {
  source      = "../../../../modules/self-service/app-sqs-queue"
  app_name    = "app2"
  environment = var.environment
  queue_name  = "app2-queue"
}

module "s3" {
  source      = "../../../../modules/self-service/app-s3-bucket"
  app_name    = "app2"
  environment = var.environment
  team        = "team-app2"
  bucket_suffix = "assets"
}
