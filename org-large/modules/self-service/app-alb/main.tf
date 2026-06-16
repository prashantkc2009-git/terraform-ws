resource "aws_security_group" "alb" {
  name        = "${var.app_name}-${var.environment}-alb-sg"
  description = "Security group for ALB"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = var.listener_port
    to_port     = var.listener_port
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
    Name        = "${var.app_name}-${var.environment}-alb-sg"
    Environment = var.environment
    AppName     = var.app_name
  }
}

resource "aws_lb" "main" {
  name                       = "${var.app_name}-${var.environment}-alb"
  internal                   = false
  load_balancer_type         = "application"
  subnets                    = var.subnet_ids
  security_groups            = [aws_security_group.alb.id]
  enable_deletion_protection = var.environment == "prod"

  tags = {
    Name        = "${var.app_name}-${var.environment}-alb"
    Environment = var.environment
    AppName     = var.app_name
  }
}

resource "aws_lb_target_group" "main" {
  name     = "${var.app_name}-${var.environment}-tg"
  port     = var.target_port
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  target_type = var.target_type

  health_check {
    enabled             = true
    interval            = 30
    path                = var.health_check_path
    port                = var.target_port
    protocol            = "HTTP"
    healthy_threshold   = 2
    unhealthy_threshold = 5
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
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }
}
