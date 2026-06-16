output "kms_key_arn" {
  value       = aws_kms_key.mrk_primary.arn
  description = "KMS Primary Multi-Region Key ARN"
}

output "kms_key_id" {
  value       = aws_kms_key.mrk_primary.key_id
  description = "KMS Primary Multi-Region Key ID"
}

output "kms_key_alias" {
  value       = aws_kms_alias.mrk_primary_alias.name
  description = "KMS Key alias"
}
