resource "random_password" "main" {
  for_each = var.secrets

  length  = try(each.value.length, 24)
  special = try(each.value.special, true)
  upper   = try(each.value.upper, true)
  lower   = try(each.value.lower, true)
  numeric = try(each.value.numeric, true)
}

resource "aws_secretsmanager_secret" "main" {
  for_each = var.secrets

  name                    = "${var.project_name}-${var.environment}-${each.key}"
  description             = try(each.value.description, "${each.key} secret")
  kms_key_id              = var.kms_key_arn
  recovery_window_in_days = var.recovery_window_days

  tags = {
    Name        = "${var.project_name}-${var.environment}-${each.key}"
    Environment = var.environment
  }
}

resource "aws_secretsmanager_secret_version" "main" {
  for_each = var.secrets

  secret_id     = aws_secretsmanager_secret.main[each.key].id
  secret_string = try(each.value.value, random_password.main[each.key].result)
}

resource "aws_lambda_function" "rotation" {
  for_each = {
    for k, v in var.secrets : k => v if try(v.enable_rotation, false)
  }

  filename         = data.archive_file.rotation[each.key].output_path
  function_name    = "${var.project_name}-${var.environment}-${each.key}-rotation"
  role             = aws_iam_role.rotation[each.key].arn
  handler          = "rotation.lambda_handler"
  runtime          = "python3.11"
  timeout          = 120
  source_code_hash = data.archive_file.rotation[each.key].output_base64sha256
}

data "archive_file" "rotation" {
  for_each = {
    for k, v in var.secrets : k => v if try(v.enable_rotation, false)
  }

  type        = "zip"
  output_path = "${path.module}/rotation_${each.key}.zip"
  source {
    content  = <<-EOT
import boto3, json, os

def lambda_handler(event, context):
    secret_id = event['SecretId']
    client = boto3.client('secretsmanager')
    client.put_secret_value(SecretId=secret_id, SecretString=os.urandom(24).hex())
    return {'status': 'rotated'}
EOT
    filename = "rotation.py"
  }
}

resource "aws_iam_role" "rotation" {
  for_each = {
    for k, v in var.secrets : k => v if try(v.enable_rotation, false)
  }

  name = "${var.project_name}-${var.environment}-${each.key}-rotation-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "rotation" {
  for_each = {
    for k, v in var.secrets : k => v if try(v.enable_rotation, false)
  }

  role       = aws_iam_role.rotation[each.key].name
  policy_arn = "arn:aws:iam::aws:policy/SecretsManagerReadWrite"
}

resource "aws_secretsmanager_secret_rotation" "main" {
  for_each = {
    for k, v in var.secrets : k => v if try(v.enable_rotation, false)
  }

  secret_id           = aws_secretsmanager_secret.main[each.key].id
  rotation_lambda_arn = aws_lambda_function.rotation[each.key].arn

  rotation_rules {
    automatically_after_days = try(each.value.rotation_days, 14)
  }
}
