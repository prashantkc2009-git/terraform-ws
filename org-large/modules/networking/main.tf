# ==============================================================================
# Module: networking
# File: main.tf
# Description: Implements multi-region networking, Cloud WAN Core, and Network Firewall.
# ==============================================================================

# 1. Global Network Manager (Cloud WAN Core)
resource "aws_networkmanager_global_network" "main" {
  description = "Global network for ${var.project_name} enterprise connectivity"

  tags = {
    Name        = "${var.project_name}-global-net"
    Environment = var.environment
  }
}

resource "aws_networkmanager_core_network" "core" {
  global_network_id = aws_networkmanager_global_network.main.id
  description       = "Cloud WAN Core Network"

  tags = {
    Name        = "${var.project_name}-core-net"
    Environment = var.environment
  }
}


data "aws_networkmanager_core_network_policy_document" "core_policy" {
  core_network_configuration {
    asn_ranges = ["64512-64555"]
    edge_locations {
      location = "us-east-1"
      asn      = 64512
    }
    edge_locations {
      location = "eu-west-1"
      asn      = 64513
    }
  }

  segments {
    name                          = "workloads"
    require_attachment_acceptance = false
  }

  segments {
    name                          = "security"
    require_attachment_acceptance = false
  }
}

resource "aws_networkmanager_core_network_policy_attachment" "core_policy_attach" {
  core_network_id = aws_networkmanager_core_network.core.id
  policy_document = data.aws_networkmanager_core_network_policy_document.core_policy.json
}


# 2. Main Workload VPC
resource "aws_vpc" "workload" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "${var.project_name}-${var.environment}-workload-vpc"
    Environment = var.environment
  }
}

# Subnets for Workload
resource "aws_subnet" "public" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.workload.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index % length(var.availability_zones)]
  map_public_ip_on_launch = true

  tags = {
    Name        = "${var.project_name}-${var.environment}-public-${count.index}"
    Environment = var.environment
  }
}

resource "aws_subnet" "private" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.workload.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index % length(var.availability_zones)]

  tags = {
    Name        = "${var.project_name}-${var.environment}-private-${count.index}"
    Environment = var.environment
  }
}

resource "aws_subnet" "data" {
  count             = length(var.data_subnet_cidrs)
  vpc_id            = aws_vpc.workload.id
  cidr_block        = var.data_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index % length(var.availability_zones)]

  tags = {
    Name        = "${var.project_name}-${var.environment}-data-${count.index}"
    Environment = var.environment
  }
}

# 3. Security Group Tiering (Strict)
resource "aws_security_group" "ingress_alb" {
  name        = "${var.project_name}-${var.environment}-ingress-alb-sg"
  description = "Security Group for Public Ingress ALBs"
  vpc_id      = aws_vpc.workload.id

  # Inbound HTTPS from anywhere or managed prefix list (CloudFront)
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
    Name        = "${var.project_name}-${var.environment}-ingress-alb-sg"
    Environment = var.environment
  }
}

resource "aws_security_group" "private_eks" {
  name        = "${var.project_name}-${var.environment}-private-eks-sg"
  description = "Security Group for EKS cluster nodes and control plane"
  vpc_id      = aws_vpc.workload.id

  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.ingress_alb.id]
  }

  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.ingress_alb.id]
  }

  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    self      = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-private-eks-sg"
    Environment = var.environment
  }
}

resource "aws_security_group" "data_tier" {
  name        = "${var.project_name}-${var.environment}-data-tier-sg"
  description = "Security Group for Aurora, DynamoDB & Cache layers"
  vpc_id      = aws_vpc.workload.id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.private_eks.id]
  }

  ingress {
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.private_eks.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-data-tier-sg"
    Environment = var.environment
  }
}

# 4. Centralized Network Firewall (Inspection VPC)
resource "aws_vpc" "inspection" {
  cidr_block           = "10.250.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "${var.project_name}-${var.environment}-inspection-vpc"
    Environment = var.environment
  }
}

resource "aws_subnet" "inspection" {
  count             = 2
  vpc_id            = aws_vpc.inspection.id
  cidr_block        = "10.250.${count.index + 1}.0/24"
  availability_zone = var.availability_zones[count.index % length(var.availability_zones)]

  tags = {
    Name        = "${var.project_name}-${var.environment}-inspection-subnet-${count.index}"
    Environment = var.environment
  }
}

resource "aws_networkfirewall_firewall_policy" "main" {
  name = "${var.project_name}-${var.environment}-fw-policy"

  firewall_policy {
    stateless_default_actions          = ["aws:forward_to_sfe"]
    stateless_fragment_default_actions = ["aws:forward_to_sfe"]
  }
}

resource "aws_networkfirewall_firewall" "main" {
  name                = "${var.project_name}-${var.environment}-net-fw"
  firewall_policy_arn = aws_networkfirewall_firewall_policy.main.arn
  vpc_id              = aws_vpc.inspection.id

  subnet_mapping {
    subnet_id = aws_subnet.inspection[0].id
  }

  subnet_mapping {
    subnet_id = aws_subnet.inspection[1].id
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-firewall"
    Environment = var.environment
  }
}

# 5. Redundant Site-to-Site VPN (Placeholder to model Workload E redundancy)
resource "aws_customer_gateway" "on_prem" {
  bgp_asn    = 65000
  ip_address = "203.0.113.12"
  type       = "ipsec.1"

  tags = {
    Name        = "${var.project_name}-${var.environment}-cgw"
    Environment = var.environment
  }
}

resource "aws_vpn_gateway" "vpn_gw" {
  vpc_id = aws_vpc.workload.id

  tags = {
    Name        = "${var.project_name}-${var.environment}-vgw"
    Environment = var.environment
  }
}

resource "aws_vpn_connection" "on_prem_vpn" {
  vpn_gateway_id      = aws_vpn_gateway.vpn_gw.id
  customer_gateway_id = aws_customer_gateway.on_prem.id
  type                = "ipsec.1"
  static_routes_only  = true

  tags = {
    Name        = "${var.project_name}-${var.environment}-vpn"
    Environment = var.environment
  }
}
