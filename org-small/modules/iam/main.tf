# ==============================================================================
# Module: iam
# File: main.tf
# Description: Provisions IAM Roles, Policies, OIDC providers, and Instance Profiles
#              governing least-privilege operations across compute types.
# ==============================================================================

# ------------------------------------------------------------------------------
# GITHUB ACTIONS OIDC IDENTITY PROVIDER & TRUST CONFIGURATION
# ------------------------------------------------------------------------------

# GitHub OIDC Identity Provider setup (standard configuration)
resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1", "1c58a3a8518e8759bf075b76b750d4f2df264fcd"]

  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# ------------------------------------------------------------------------------
# 1. EC2 LEGACY WORKLOAD ROLE (Workload A)
# ------------------------------------------------------------------------------
resource "aws_iam_role" "ec2_legacy" {
  name = "${var.project_name}-${var.environment}-ec2-legacy-role"

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

  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# Attach AWS managed SSM core policies
resource "aws_iam_role_policy_attachment" "ec2_legacy_ssm" {
  role       = aws_iam_role.ec2_legacy.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Inline policy for additional logs, S3 reads, and Secrets Manager reads
resource "aws_iam_role_policy" "ec2_legacy_custom" {
  name = "${var.project_name}-${var.environment}-ec2-legacy-custom-policy"
  role = aws_iam_role.ec2_legacy.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "secretsmanager:GetSecretValue",
          "ssm:GetParameter",
          "ssm:GetParameters"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "cloudwatch:PutMetricData",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_instance_profile" "ec2_legacy" {
  name = "${var.project_name}-${var.environment}-ec2-legacy-profile"
  role = aws_iam_role.ec2_legacy.name

  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# ------------------------------------------------------------------------------
# 2. AUTO-SCALING GROUP API SERVICE ROLE (Workload B)
# ------------------------------------------------------------------------------
resource "aws_iam_role" "asg_api" {
  name = "${var.project_name}-${var.environment}-asg-api-role"

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

  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

resource "aws_iam_role_policy_attachment" "asg_api_ssm" {
  role       = aws_iam_role.asg_api.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy" "asg_api_custom" {
  name = "${var.project_name}-${var.environment}-asg-api-custom-policy"
  role = aws_iam_role.asg_api.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetAuthorizationToken"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "secretsmanager:GetSecretValue",
          "ssm:GetParameter",
          "ssm:GetParameters"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_instance_profile" "asg_api" {
  name = "${var.project_name}-${var.environment}-asg-api-profile"
  role = aws_iam_role.asg_api.name

  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# ------------------------------------------------------------------------------
# 3. EKS CLUSTER ROLE (Workload C)
# ------------------------------------------------------------------------------
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

  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

resource "aws_iam_role_policy_attachment" "eks_cluster" {
  role       = aws_iam_role.eks_cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# ------------------------------------------------------------------------------
# 4. EKS NODE GROUP ROLE (Workload C Worker Nodes)
# ------------------------------------------------------------------------------
resource "aws_iam_role" "eks_node" {
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

  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

resource "aws_iam_role_policy_attachment" "eks_node_worker" {
  role       = aws_iam_role.eks_node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "eks_node_cni" {
  role       = aws_iam_role.eks_node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "eks_node_ecr" {
  role       = aws_iam_role.eks_node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "eks_node_ssm" {
  role       = aws_iam_role.eks_node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# ------------------------------------------------------------------------------
# 5. GITHUB ACTIONS DEPLOYMENT OIDC ROLE
# ------------------------------------------------------------------------------
resource "aws_iam_role" "github_actions" {
  name = "${var.project_name}-${var.environment}-github-actions-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:repo" = var.github_repo
          }
        }
      }
    ]
  })

  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

resource "aws_iam_role_policy" "github_actions" {
  name = "${var.project_name}-${var.environment}-github-actions-policy"
  role = aws_iam_role.github_actions.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ecr:*",
          "ecs:*",
          "s3:*",
          "iam:PassRole",
          "ssm:StartSession"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

# ------------------------------------------------------------------------------
# 6. AWS BACKUP ROLE
# ------------------------------------------------------------------------------
resource "aws_iam_role" "backup" {
  name = "${var.project_name}-${var.environment}-backup-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "backup.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

resource "aws_iam_role_policy_attachment" "backup" {
  role       = aws_iam_role.backup.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
}

# ------------------------------------------------------------------------------
# 7. SRE READONLY ROLE
# ------------------------------------------------------------------------------
resource "aws_iam_role" "sre_readonly" {
  name = "${var.project_name}-${var.environment}-sre-readonly-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ssm.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

resource "aws_iam_role_policy_attachment" "sre_readonly" {
  role       = aws_iam_role.sre_readonly.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

# ------------------------------------------------------------------------------
# WRITE OUTPUTS TO AWS SSM PARAMETER STORE (SSM Coupling Setup)
# ------------------------------------------------------------------------------
resource "aws_ssm_parameter" "ec2_legacy_profile" {
  name        = "/company-small/${var.environment}/iam/ec2_legacy_profile"
  type        = "String"
  value       = aws_iam_instance_profile.ec2_legacy.name
  description = "EC2 Legacy Instance Profile name"
}

resource "aws_ssm_parameter" "asg_api_profile" {
  name        = "/company-small/${var.environment}/iam/asg_api_profile"
  type        = "String"
  value       = aws_iam_instance_profile.asg_api.name
  description = "ASG API Instance Profile name"
}

resource "aws_ssm_parameter" "eks_cluster_role_arn" {
  name        = "/company-small/${var.environment}/iam/eks_cluster_role_arn"
  type        = "String"
  value       = aws_iam_role.eks_cluster.arn
  description = "EKS Cluster IAM role ARN"
}

resource "aws_ssm_parameter" "eks_node_role_arn" {
  name        = "/company-small/${var.environment}/iam/eks_node_role_arn"
  type        = "String"
  value       = aws_iam_role.eks_node.arn
  description = "EKS Node IAM role ARN"
}
