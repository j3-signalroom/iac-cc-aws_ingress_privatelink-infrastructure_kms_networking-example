variable "aws_region" {
  description = "AWS region where the KMS key will be created."
  type        = string
}

variable "kafka_cluster_name" {
  description = "Name of the Confluent Cloud Kafka cluster that will use the BYOK key for encryption."
  type        = string
}