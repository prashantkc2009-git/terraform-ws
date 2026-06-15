# ==============================================================================
# Module: compute
# File: main.tf
# Description: Configures EKS Fleet, SageMaker configurations, and Legacy EC2.
# ==============================================================================

# 1. IAM Role for EKS Cluster
resource "aws_iam_role" "eks_cluster" {
  name = "${var.project_name}-${var.environment}-eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster.name
}

# IAM Role for EKS Node Group
resource "aws_iam_role" "eks_nodes" {
  name = "${var.project_name}-${var.environment}-eks-node-role"

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
  role       = aws_iam_role.eks_nodes.name
}

resource "aws_iam_role_policy_attachment" "eks_cni" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_nodes.name
}

resource "aws_iam_role_policy_attachment" "ecr_readonly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_nodes.name
}

# 2. EKS Cluster
resource "aws_eks_cluster" "main" {
  name     = "${var.project_name}-${var.environment}-eks"
  role_arn = aws_iam_role.eks_cluster.arn
  version  = var.kubernetes_version

  vpc_config {
    subnet_ids              = var.private_subnet_ids
    security_group_ids      = [var.private_eks_sg_id]
    endpoint_private_access = true
    endpoint_public_access  = false # Private-only control plane
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy
  ]

  tags = {
    Name        = "${var.project_name}-${var.environment}-eks"
    Environment = var.environment
  }
}

# 3. Karpenter Managed Node Group (On-Demand & Spot Mix)
# Primary On-Demand Node Group
resource "aws_eks_node_group" "on_demand" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.project_name}-${var.environment}-on-demand"
  node_role_arn   = aws_iam_role.eks_nodes.arn
  subnet_ids      = var.private_subnet_ids

  scaling_config {
    desired_size = 3
    max_size     = 10
    min_size     = 2
  }

  instance_types = ["m7i.2xlarge"]
  capacity_type  = "ON_DEMAND"

  labels = {
    "capacity-type" = "on-demand"
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-on-demand-nodes"
    Environment = var.environment
  }
}

# Spot Node Group
resource "aws_eks_node_group" "spot" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.project_name}-${var.environment}-spot"
  node_role_arn   = aws_iam_role.eks_nodes.arn
  subnet_ids      = var.private_subnet_ids

  scaling_config {
    desired_size = 2
    max_size     = 20
    min_size     = 0
  }

  instance_types = ["m7i.4xlarge", "r7i.2xlarge"]
  capacity_type  = "SPOT"

  labels = {
    "capacity-type" = "spot"
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-spot-nodes"
    Environment = var.environment
  }
}

# 4. SageMaker Core Infrastructure (Workload C - AI/ML Inference)
resource "aws_sagemaker_domain" "ml_domain" {
  domain_name = "${var.project_name}-${var.environment}-sagemaker-domain"
  auth_mode   = "IAM"
  vpc_id      = var.vpc_id
  subnet_ids  = var.private_subnet_ids

  default_user_settings {
    execution_role = aws_iam_role.eks_nodes.arn # In production, a dedicated SageMaker Execution role is used
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-sagemaker"
    Environment = var.environment
  }
}

# 5. Hybrid Legacy Systems (Workload E)
# Dedicated Bare Metal equivalent or high-memory EC2 instance modeling co-located mainframe integrations
resource "aws_instance" "legacy_mainframe_connector" {
  ami           = "ami-0c55b159cbfafe1f0" # Placeholder AMI
  instance_type = "m7i-metal-24xl"        # Bare Metal as per design doc
  subnet_id     = var.private_subnet_ids[0]
  tenancy       = "dedicated" # Single tenant dedicated hardware

  tags = {
    Name        = "${var.project_name}-${var.environment}-legacy-connector"
    Environment = var.environment
  }
}
