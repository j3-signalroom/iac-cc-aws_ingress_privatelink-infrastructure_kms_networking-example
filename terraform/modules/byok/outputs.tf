output "byok_key" {
  description = "The ID of the KMS key registered with Confluent Cloud for BYOK encryption."
  value       = confluent_byok_key.cluster.id
}