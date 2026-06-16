resource "aws_security_group" "nlb" {
  name        = "${var.app_name}-${var.environment}-nlb-sg"
  description = "Security group for NLB"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = var.listener_port
    to_port     = var.listener_port
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.app_name}-${var.environment}-nlb-sg"
    Environment = var.environment
    AppName     = var.app_name
  }
}

resource "aws_lb" "main" {
  name                       = "${var.app_name}-${var.environment}-nlb"
  internal                   = false
  load_balancer_type         = "network"
  subnets                    = var.subnet_ids
  enable_deletion_protection = var.environment == "prod"

  tags = {
    Name        = "${var.app_name}-${var.environment}-nlb"
    Environment = var.environment
    AppName     = var.app_name
  }
}

resource "aws_lb_target_group" "main" {
  name     = "${var.app_name}-${var.environment}-tg"
  port     = var.target_port
  protocol = "TCP"
  vpc_id   = var.vpc_id

  health_check {
    enabled             = true
    interval            = 30
    port                = var.target_port
    protocol            = "TCP"
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }

  tags = {
    Name        = "${var.app_name}-${var.environment}-tg"
    Environment = var.environment
    AppName     = var.app_name
  }
}

resource "aws_lb_listener" "main" {
  load_balancer_arn = aws_lb.main.arn
  port              = var.listener_port
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }
}
