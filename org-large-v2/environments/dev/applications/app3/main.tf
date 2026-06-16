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

# Fetch the data subnets tagged in the base network VPC
data "aws_subnets" "data" {
  filter {
    name   = "vpc-id"
    values = [data.aws_ssm_parameter.vpc_id.value]
  }
  filter {
    name   = "tag:Name"
    values = ["*-data-*"]
  }
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

# 2. Aurora Database Module Call using relative path (uncomment Git Source URL when migrating)
module "aurora_database" {
  # source          = "git::https://github.com/prashantkc2009-git/terraform-ws.git//org-large-v2/modules/shared/aurora-global-database?ref=main"
  source          = "../../../../modules/shared/aurora-global-database"
  environment     = var.environment
  project_name    = "company-large"
  vpc_id          = data.aws_ssm_parameter.vpc_id.value
  data_subnet_ids = data.aws_subnets.data.ids
  data_tier_sg_id = aws_security_group.db_sg.id
  kms_key_arn     = data.aws_ssm_parameter.kms_key_arn.value
  database_name   = "${var.app_name}db"
  master_password = var.aurora_master_password
  instance_count  = 1
}

# Security Group for App 3 Database
resource "aws_security_group" "db_sg" {
  name        = "${var.app_name}-${var.environment}-db-sg"
  description = "Security group for App 3 Aurora database"
  vpc_id      = data.aws_ssm_parameter.vpc_id.value

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.vm_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.app_name}-${var.environment}-db-sg"
    Environment = var.environment
  }
}

# Security Group for App 3 VMs
resource "aws_security_group" "vm_sg" {
  name        = "${var.app_name}-${var.environment}-vm-sg"
  description = "Security group for App 3 VM instances"
  vpc_id      = data.aws_ssm_parameter.vpc_id.value

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Assumes port 80 is allowed for HTTP/NLB
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.app_name}-${var.environment}-vm-sg"
    Environment = var.environment
  }
}

# Fetch Amazon Linux 2 AMI
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# 3. Virtual Machines (1 VM in each private subnet/AZ - total of 3)
resource "aws_instance" "vm" {
  count                  = 3
  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = "t3.micro"
  subnet_id              = split(",", data.aws_ssm_parameter.private_subnet_ids.value)[count.index]
  vpc_security_group_ids = [aws_security_group.vm_sg.id]

  tags = {
    Name        = "${var.app_name}-${var.environment}-vm-${count.index}"
    Environment = var.environment
    AppName     = var.app_name
  }
}

# 4. Network Load Balancer (NLB) in Public Subnets
resource "aws_lb" "nlb" {
  name               = "${var.app_name}-${var.environment}-nlb"
  load_balancer_type = "network"
  subnets            = split(",", data.aws_ssm_parameter.public_subnet_ids.value)

  tags = {
    Name        = "${var.app_name}-${var.environment}-nlb"
    Environment = var.environment
    AppName     = var.app_name
  }
}

resource "aws_lb_target_group" "tg" {
  name        = "${var.app_name}-${var.environment}-tg"
  port        = 80
  protocol    = "TCP"
  vpc_id      = data.aws_ssm_parameter.vpc_id.value
  target_type = "instance"
}

resource "aws_lb_target_group_attachment" "tg_attachment" {
  count            = 3
  target_group_arn = aws_lb_target_group.tg.arn
  target_id        = aws_instance.vm[count.index].id
  port             = 80
}

resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.nlb.arn
  port              = 80
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}
