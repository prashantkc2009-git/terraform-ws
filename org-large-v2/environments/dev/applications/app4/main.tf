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

# 1. S3 Bucket Module Call using relative path (uncomment Git Source URL when migrating)
module "s3_bucket" {
  # source      = "git::https://github.com/prashantkc2009-git/terraform-ws.git//org-large-v2/modules/self-service/app-s3-bucket?ref=main"
  source      = "../../../../modules/self-service/app-s3-bucket"
  app_name    = var.app_name
  environment = var.environment
  team        = var.team
  kms_key_arn = data.aws_ssm_parameter.kms_key_arn.value
}

# 2. DynamoDB Database Module Call using relative path (uncomment Git Source URL when migrating)
module "dynamodb_table" {
  # source      = "git::https://github.com/prashantkc2009-git/terraform-ws.git//org-large-v2/modules/self-service/app-dynamodb-table?ref=main"
  source      = "../../../../modules/self-service/app-dynamodb-table"
  app_name    = var.app_name
  environment = var.environment
  table_name  = "data"
  hash_key    = "Id"
  attributes = [
    { name = "Id", type = "S" }
  ]
  kms_key_arn = data.aws_ssm_parameter.kms_key_arn.value
}

# 3. SQS Queue Module Call using relative path (uncomment Git Source URL when migrating)
module "sqs_queue" {
  # source      = "git::https://github.com/prashantkc2009-git/terraform-ws.git//org-large-v2/modules/self-service/app-sqs-queue?ref=main"
  source      = "../../../../modules/self-service/app-sqs-queue"
  app_name    = var.app_name
  environment = var.environment
  queue_name  = "jobs"
  kms_key_id  = data.aws_ssm_parameter.kms_key_arn.value
}

# 4. EKS Dedicated Node Group (2 Nodes) on the Shared EKS Cluster
resource "aws_iam_role" "node_role" {
  name = "${var.app_name}-${var.environment}-eks-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_worker_node" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.node_role.name
}

resource "aws_iam_role_policy_attachment" "eks_cni" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.node_role.name
}

resource "aws_iam_role_policy_attachment" "ecr_readonly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.node_role.name
}

resource "aws_eks_node_group" "app4_nodes" {
  cluster_name    = data.aws_ssm_parameter.eks_cluster_name.value
  node_group_name = "${var.app_name}-${var.environment}-nodes"
  node_role_arn   = aws_iam_role.node_role.arn
  subnet_ids      = split(",", data.aws_ssm_parameter.private_subnet_ids.value)

  scaling_config {
    desired_size = 2
    max_size     = 4
    min_size     = 1
  }

  instance_types = ["t3.medium"]
  capacity_type  = "ON_DEMAND"

  labels = {
    app = var.app_name
  }

  tags = {
    Name        = "${var.app_name}-${var.environment}-nodes"
    Environment = var.environment
    AppName     = var.app_name
  }
}

# 5. Application Load Balancer (ALB) for Layer 7 Routing
resource "aws_security_group" "alb_sg" {
  name        = "${var.app_name}-${var.environment}-alb-sg"
  description = "Security group for App 4 ALB"
  vpc_id      = data.aws_ssm_parameter.vpc_id.value

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.app_name}-${var.environment}-alb-sg"
    Environment = var.environment
  }
}

resource "aws_lb" "alb" {
  name               = "${var.app_name}-${var.environment}-alb"
  load_balancer_type = "application"
  subnets            = split(",", data.aws_ssm_parameter.public_subnet_ids.value)
  security_groups    = [aws_security_group.alb_sg.id]

  tags = {
    Name        = "${var.app_name}-${var.environment}-alb"
    Environment = var.environment
    AppName     = var.app_name
  }
}

resource "aws_lb_target_group" "tg" {
  name        = "${var.app_name}-${var.environment}-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = data.aws_ssm_parameter.vpc_id.value
  target_type = "ip" # EKS target routing usually targets pod IPs
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}
