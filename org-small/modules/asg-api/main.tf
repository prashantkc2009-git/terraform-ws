# ==============================================================================
# Module: asg-api
# File: main.tf
# Description: Provisions the Application Load Balancer, Launch Template, Auto Scaling
#              Group, CPU Target Tracking Policies, and DNS Record for Workload B.
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
# APPLICATION LOAD BALANCER
# ------------------------------------------------------------------------------
resource "aws_lb" "api" {
  name               = "${var.project_name}-${var.environment}-api-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_sg_id]
  subnets            = var.public_subnet_ids

  enable_deletion_protection = false

  tags = {
    Name        = "${var.project_name}-${var.environment}-api-alb"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# Target Group for Workload B (stateless app tier on port 8080)
resource "aws_lb_target_group" "api" {
  name        = "${var.project_name}-${var.environment}-api-tg"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "instance"

  health_check {
    path                = "/health"
    port                = "8080"
    protocol            = "HTTP"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-api-tg"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# HTTP Redirect Listener (Port 80 -> HTTPS Port 443)
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.api.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# HTTPS Listener (Port 443 -> TG Port 8080)
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.api.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = var.acm_certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api.arn
  }
}

# ------------------------------------------------------------------------------
# LAUNCH TEMPLATE
# ------------------------------------------------------------------------------
resource "aws_launch_template" "api" {
  name_prefix   = "${var.project_name}-${var.environment}-api-lt-"
  image_id      = data.aws_ami.al2023.id
  instance_type = var.instance_type

  iam_instance_profile {
    name = var.iam_instance_profile_name
  }

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [var.app_sg_id]
  }

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size           = 50
      volume_type           = "gp3"
      encrypted             = true
      kms_key_id            = var.kms_key_arn
      delete_on_termination = true
    }
  }

  user_data = base64encode(<<-EOF
              #!/bin/bash
              echo "Initializing API workload instance"
              # App setup would occur here
              EOF
  )

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-api-lt"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# ------------------------------------------------------------------------------
# AUTO SCALING GROUP
# ------------------------------------------------------------------------------
resource "aws_autoscaling_group" "api" {
  name_prefix         = "${var.project_name}-${var.environment}-api-asg-"
  vpc_zone_identifier = var.private_subnet_ids
  target_group_arns   = [aws_lb_target_group.api.arn]

  min_size         = var.asg_min_size
  max_size         = var.asg_max_size
  desired_capacity = var.asg_desired_size

  health_check_type         = "ELB"
  health_check_grace_period = 300
  force_delete              = false

  launch_template {
    id      = aws_launch_template.api.id
    version = "$Latest"
  }

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
    triggers = ["tag"]
  }

  dynamic "tag" {
    for_each = {
      Name        = "${var.project_name}-${var.environment}-api-worker"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [desired_capacity]
  }
}

# ------------------------------------------------------------------------------
# SCALING POLICIES (Target Tracking - CPU 60%)
# ------------------------------------------------------------------------------
resource "aws_autoscaling_policy" "cpu_scaling" {
  name                   = "${var.project_name}-${var.environment}-api-cpu-scaling"
  policy_type            = "TargetTrackingScaling"
  autoscaling_group_name = aws_autoscaling_group.api.name

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = var.target_cpu_utilization
  }
}

# ------------------------------------------------------------------------------
# SCHEDULED SCALING (Peak Hours Scale-Up / Scale-Down)
# ------------------------------------------------------------------------------
# Scale-up at 7:00 AM UTC
resource "aws_autoscaling_schedule" "scale_up_peak" {
  scheduled_action_name  = "scale-up-peak"
  min_size               = var.asg_min_size
  max_size               = var.asg_max_size
  desired_capacity       = var.asg_max_size
  recurrence             = "0 7 * * 1-5" # Mon-Fri at 7am UTC
  autoscaling_group_name = aws_autoscaling_group.api.name
}

# Scale-down at 8:00 PM UTC
resource "aws_autoscaling_schedule" "scale_down_offpeak" {
  scheduled_action_name  = "scale-down-offpeak"
  min_size               = var.asg_min_size
  max_size               = var.asg_max_size
  desired_capacity       = var.asg_min_size
  recurrence             = "0 20 * * 1-5" # Mon-Fri at 8pm UTC
  autoscaling_group_name = aws_autoscaling_group.api.name
}

# ------------------------------------------------------------------------------
# ROUTE 53 ALIAS RECORD
# ------------------------------------------------------------------------------
resource "aws_route53_record" "api" {
  zone_id = var.route53_zone_id
  name    = "api.${var.domain_name}"
  type    = "A"

  alias {
    name                   = aws_lb.api.dns_name
    zone_id                = aws_lb.api.zone_id
    evaluate_target_health = true
  }
}
