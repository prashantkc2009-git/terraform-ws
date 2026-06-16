resource "aws_vpc" "inspection" {
  cidr_block           = var.inspection_vpc_cidr
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
