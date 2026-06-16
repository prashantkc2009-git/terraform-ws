resource "aws_controltower_control" "mandatory_guardrails" {
  for_each = var.enable_guardrails ? toset([
    "AWS-GR_AUDIT_BUCKET_PUBLIC_READ_PROHIBITED",
    "AWS-GR_AUDIT_BUCKET_PUBLIC_WRITE_PROHIBITED",
    "AWS-GR_ENCRYPTED_VOLUMES",
    "AWS-GR_RESTRICTED_COMMON_PORTS",
    "AWS-GR_S3_BUCKET_PUBLIC_READ_PROHIBITED",
    "AWS-GR_S3_BUCKET_PUBLIC_WRITE_PROHIBITED",
    "AWS-GR_SUBNET_AUTO_ASSIGN_PUBLIC_IP_DISABLED",
  ]) : []

  target_identifier = var.root_ou_id
  control_identifier = each.value
}
