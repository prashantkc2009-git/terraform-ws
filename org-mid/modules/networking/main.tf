# ==============================================================================
# Module: networking
# File: main.tf
# Description: Implements VPC and subnet tiers according to company-mid design.
# ==============================================================================

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "${var.project_name}-${var.environment}-vpc"
    Environment = var.environment
  }
}

# Subnets
resource "aws_subnet" "public" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index % length(var.availability_zones)]
  map_public_ip_on_launch = true

  tags = {
    Name        = "${var.project_name}-${var.environment}-public-${count.index}"
    Environment = var.environment
    Type        = "public"
  }
}

resource "aws_subnet" "private" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index % length(var.availability_zones)]

  tags = {
    Name        = "${var.project_name}-${var.environment}-private-${count.index}"
    Environment = var.environment
    Type        = "private"
  }
}

resource "aws_subnet" "data" {
  count             = length(var.data_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.data_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index % length(var.availability_zones)]

  tags = {
    Name        = "${var.project_name}-${var.environment}-data-${count.index}"
    Environment = var.environment
    Type        = "data"
  }
}

resource "aws_subnet" "endpoint" {
  count             = length(var.endpoint_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.endpoint_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index % length(var.availability_zones)]

  tags = {
    Name        = "${var.project_name}-${var.environment}-endpoint-${count.index}"
    Environment = var.environment
    Type        = "endpoint"
  }
}

resource "aws_subnet" "tgw" {
  count             = length(var.tgw_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.tgw_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index % length(var.availability_zones)]

  tags = {
    Name        = "${var.project_name}-${var.environment}-tgw-${count.index}"
    Environment = var.environment
    Type        = "tgw"
  }
}

# Internet Gateway for public ingress (static site origins / ALBs)
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "${var.project_name}-${var.environment}-igw"
    Environment = var.environment
  }
}

# Elastic IP and NAT Gateway for private subnet outbound access
# In multi-account setups, egress is handled by the central Shared Services Egress VPC (ADR-02).
# For standalone environments (dev/staging without TGW), a local NAT GW provides outbound access.
resource "aws_eip" "nat" {
  count  = var.tgw_id == "" ? 1 : 0
  domain = "vpc"

  tags = {
    Name        = "${var.project_name}-${var.environment}-nat-eip"
    Environment = var.environment
  }
}

resource "aws_nat_gateway" "main" {
  count         = var.tgw_id == "" ? 1 : 0
  allocation_id = aws_eip.nat[0].id
  subnet_id     = aws_subnet.public[0].id

  tags = {
    Name        = "${var.project_name}-${var.environment}-nat-gw"
    Environment = var.environment
  }
}

# Route Tables
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-public-rt"
    Environment = var.environment
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  dynamic "route" {
    for_each = var.tgw_id == "" ? [1] : []
    content {
      cidr_block     = "0.0.0.0/0"
      nat_gateway_id = aws_nat_gateway.main[0].id
    }
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-private-rt"
    Environment = var.environment
  }
}

# Associations
resource "aws_route_table_association" "public" {
  count          = length(var.public_subnet_cidrs)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count          = length(var.private_subnet_cidrs)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "data" {
  count          = length(var.data_subnet_cidrs)
  subnet_id      = aws_subnet.data[count.index].id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "endpoint" {
  count          = length(var.endpoint_subnet_cidrs)
  subnet_id      = aws_subnet.endpoint[count.index].id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "tgw" {
  count          = length(var.tgw_subnet_cidrs)
  subnet_id      = aws_subnet.tgw[count.index].id
  route_table_id = aws_route_table.private.id
}

# Transit Gateway Attachment (See ADR-02)
resource "aws_ec2_transit_gateway_vpc_attachment" "tgw" {
  count              = var.tgw_id != "" ? 1 : 0
  transit_gateway_id = var.tgw_id
  vpc_id             = aws_vpc.main.id
  subnet_ids         = aws_subnet.tgw[*].id

  tags = {
    Name        = "${var.project_name}-${var.environment}-tgw-attach"
    Environment = var.environment
  }
}

# S3 Gateway Endpoint
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.us-east-1.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.private.id, aws_route_table.public.id]

  tags = {
    Name        = "${var.project_name}-${var.environment}-s3-endpoint"
    Environment = var.environment
  }
}

# Route 53 Private Hosted Zone
resource "aws_route53_zone" "private" {
  name = "internal.${var.project_name}.io"

  vpc {
    vpc_id = aws_vpc.main.id
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-private-zone"
    Environment = var.environment
  }
}

# Flow Logs (Gap G4)
resource "aws_flow_log" "main" {
  count                = var.enable_flow_logs && var.log_destination_arn != "" ? 1 : 0
  iam_role_arn         = aws_iam_role.flow_logs_role[0].arn
  log_destination      = var.log_destination_arn
  traffic_type         = "ALL"
  vpc_id               = aws_vpc.main.id
  log_destination_type = "cloud-watch-logs"
}

resource "aws_iam_role" "flow_logs_role" {
  count = var.enable_flow_logs && var.log_destination_arn != "" ? 1 : 0
  name  = "${var.project_name}-${var.environment}-flow-logs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
      }
    ]
  })
}
