output "confluent_byok_key_id" {
  description = "The ID of the KMS key registered with Confluent Cloud for BYOK encryption."
  value       = confluent_byok_key.cluster.id
}

output "aws_kms_byok_key_arn" {
  description = "The ARN of the AWS KMS key used for BYOK encryption."
  value       = aws_kms_key.byok.arn
}

output "aws_kms_byok_key_id" {
  description = "The ID of the AWS KMS key used for BYOK encryption."
  value       = aws_kms_key.byok.key_id
}