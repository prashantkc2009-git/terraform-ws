# ==============================================================================
# Module: eks
# File: main.tf
# Description: Provisions the private-only EKS Cluster and managed node groups
#              (both On-Demand and Spot) for Workload C.
# ==============================================================================

# Custom Security Group for EKS Cluster Control Plane
resource "aws_security_group" "cluster" {
  name        = "${var.project_name}-${var.environment}-eks-cluster-sg"
  description = "EKS cluster security group"
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow all traffic from within security group"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-eks-cluster-sg"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# ------------------------------------------------------------------------------
# EKS CLUSTER
# ------------------------------------------------------------------------------
resource "aws_eks_cluster" "main" {
  name     = "${var.project_name}-${var.environment}-eks-cluster"
  role_arn = var.cluster_role_arn
  version  = var.kubernetes_version

  vpc_config {
    subnet_ids              = var.private_subnet_ids
    security_group_ids      = [aws_security_group.cluster.id]
    endpoint_private_access = true
    endpoint_public_access  = false # Private-only control plane endpoint
  }

  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  tags = {
    Name        = "${var.project_name}-${var.environment}-eks-cluster"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# ------------------------------------------------------------------------------
# MANAGED NODE GROUP: ON-DEMAND
# ------------------------------------------------------------------------------
resource "aws_eks_node_group" "on_demand" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.project_name}-${var.environment}-on-demand-nodes"
  node_role_arn   = var.node_role_arn
  subnet_ids      = var.private_subnet_ids

  instance_types = var.on_demand_instance_types
  capacity_type  = "ON_DEMAND"

  scaling_config {
    desired_size = var.on_demand_desired_size
    min_size     = var.on_demand_min_size
    max_size     = var.on_demand_max_size
  }

  update_config {
    max_unavailable = 1
  }

  labels = {
    capacity-type = "on-demand"
    environment   = var.environment
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-on-demand-node"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }

  lifecycle {
    ignore_changes = [scaling_config[0].desired_size]
  }
}

# ------------------------------------------------------------------------------
# MANAGED NODE GROUP: SPOT (Burst / Scalability)
# ------------------------------------------------------------------------------
resource "aws_eks_node_group" "spot" {
  count           = var.enable_spot_nodes ? 1 : 0
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.project_name}-${var.environment}-spot-nodes"
  node_role_arn   = var.node_role_arn
  subnet_ids      = var.private_subnet_ids

  instance_types = var.spot_instance_types
  capacity_type  = "SPOT"

  scaling_config {
    desired_size = var.spot_desired_size
    min_size     = var.spot_min_size
    max_size     = var.spot_max_size
  }

  update_config {
    max_unavailable = 1
  }

  labels = {
    capacity-type = "spot"
    environment   = var.environment
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-spot-node"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }

  lifecycle {
    ignore_changes = [scaling_config[0].desired_size]
  }
}
