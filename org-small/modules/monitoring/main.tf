# ==============================================================================
# Module: monitoring
# File: main.tf
# Description: Provisions CloudWatch Metric Alarms and a unified dashboard for
#              app tier health, RDS metrics, and Auto Scaling Group performance.
# ==============================================================================

# Alarm for ASG CPU utilization (if name provided)
resource "aws_cloudwatch_metric_alarm" "asg_high_cpu" {
  count               = var.asg_name != "" ? 1 : 0
  alarm_name          = "${var.project_name}-${var.environment}-asg-high-cpu"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Triggered if ASG average CPU utilization exceeds 80% for 10 minutes."

  dimensions = {
    AutoScalingGroupName = var.asg_name
  }

  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# Alarm for RDS Free Storage Space (if instance ID provided)
resource "aws_cloudwatch_metric_alarm" "rds_low_storage" {
  count               = var.db_instance_id != "" ? 1 : 0
  alarm_name          = "${var.project_name}-${var.environment}-rds-low-storage"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = 600
  statistic           = "Average"
  threshold           = 5000000000 # 5 GB in bytes
  alarm_description   = "Triggered if RDS free storage space falls below 5 GB."

  dimensions = {
    DBInstanceIdentifier = var.db_instance_id
  }

  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# Unified CloudWatch Dashboard
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.project_name}-${var.environment}-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/EC2", "CPUUtilization", "AutoScalingGroupName", var.asg_name]
          ]
          period = 300
          stat   = "Average"
          region = "us-east-1"
          title  = "ASG Average CPU Utilization"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/RDS", "FreeStorageSpace", "DBInstanceIdentifier", var.db_instance_id]
          ]
          period = 600
          stat   = "Average"
          region = "us-east-1"
          title  = "RDS Free Storage Space"
        }
      }
    ]
  })
}
