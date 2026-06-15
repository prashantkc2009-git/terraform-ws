# ==============================================================================
# Module: ec2-legacy
# File: main.tf
# Description: Provisions the active and pilot-light standby EC2 instances for
#              Workload A (legacy monolith), using KMS encrypted gp3 volumes.
# ==============================================================================

# Data source for latest Amazon Linux 2023 AMI
data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# ------------------------------------------------------------------------------
# ACTIVE MONOLITH INSTANCE
# ------------------------------------------------------------------------------
resource "aws_instance" "active" {
  ami                  = data.aws_ami.al2023.id
  instance_type        = var.instance_type_active
  subnet_id            = var.private_subnet_ids[0]
  vpc_security_group_ids = [var.app_sg_id]
  iam_instance_profile = var.iam_instance_profile_name

  root_block_device {
    volume_size           = var.root_volume_size
    volume_type           = "gp3"
    encrypted             = true
    kms_key_id            = var.kms_key_arn
    delete_on_termination = true

    tags = {
      Name        = "${var.project_name}-${var.environment}-ec2-legacy-active-root"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }

  user_data = <<-EOF
              #!/bin/bash
              echo "Initializing Legacy Monolith Active instance"
              # Mount secondary block device if attached
              mkdir -p /data
              # Wait for volume to attach
              while [ ! -b /dev/sdb ]; do sleep 1; done
              if ! grep -q "/data" /etc/fstab; then
                mkfs -t xfs /dev/sdb
                echo "/dev/sdb /data xfs defaults,nofail 0 2" >> /etc/fstab
                mount -a
              fi
              EOF

  tags = {
    Name        = "${var.project_name}-${var.environment}-ec2-legacy-active"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# Secondary data EBS volume for active
resource "aws_ebs_volume" "active_data" {
  availability_zone = aws_instance.active.availability_zone
  size              = var.data_volume_size
  type              = "gp3"
  encrypted         = true
  kms_key_id        = var.kms_key_arn

  tags = {
    Name        = "${var.project_name}-${var.environment}-ec2-legacy-active-data"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# Volume attachment for active
resource "aws_volume_attachment" "active_data" {
  device_name = "/dev/sdb"
  volume_id   = aws_ebs_volume.active_data.id
  instance_id = aws_instance.active.id
}

# ------------------------------------------------------------------------------
# STANDBY MONOLITH INSTANCE (Pilot-light, stopped state)
# ------------------------------------------------------------------------------
resource "aws_instance" "standby" {
  count                = var.create_standby ? 1 : 0
  ami                  = data.aws_ami.al2023.id
  instance_type        = var.instance_type_standby
  # Deploy in secondary AZ/subnet
  subnet_id            = length(var.private_subnet_ids) > 1 ? var.private_subnet_ids[1] : var.private_subnet_ids[0]
  vpc_security_group_ids = [var.app_sg_id]
  iam_instance_profile = var.iam_instance_profile_name

  root_block_device {
    volume_size           = var.root_volume_size
    volume_type           = "gp3"
    encrypted             = true
    kms_key_id            = var.kms_key_arn
    delete_on_termination = true

    tags = {
      Name        = "${var.project_name}-${var.environment}-ec2-legacy-standby-root"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }

  user_data = <<-EOF
              #!/bin/bash
              echo "Initializing Legacy Monolith Standby instance"
              mkdir -p /data
              while [ ! -b /dev/sdb ]; do sleep 1; done
              if ! grep -q "/data" /etc/fstab; then
                mkfs -t xfs /dev/sdb
                echo "/dev/sdb /data xfs defaults,nofail 0 2" >> /etc/fstab
                mount -a
              fi
              EOF

  tags = {
    Name        = "${var.project_name}-${var.environment}-ec2-legacy-standby"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# Secondary data EBS volume for standby
resource "aws_ebs_volume" "standby_data" {
  count             = var.create_standby ? 1 : 0
  availability_zone = aws_instance.standby[0].availability_zone
  size              = var.data_volume_size
  type              = "gp3"
  encrypted         = true
  kms_key_id        = var.kms_key_arn

  tags = {
    Name        = "${var.project_name}-${var.environment}-ec2-legacy-standby-data"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# Volume attachment for standby
resource "aws_volume_attachment" "standby_data" {
  count       = var.create_standby ? 1 : 0
  device_name = "/dev/sdb"
  volume_id   = aws_ebs_volume.standby_data[0].id
  instance_id = aws_instance.standby[0].id
}

# State management to keep standby instance stopped (pilot-light recovery model)
resource "aws_ec2_instance_state" "standby" {
  count       = var.create_standby ? 1 : 0
  instance_id = aws_instance.standby[0].id
  state       = "stopped"
}
