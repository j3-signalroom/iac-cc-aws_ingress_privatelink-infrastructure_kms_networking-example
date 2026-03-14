# Creates an AWS KMS key intended to allow you to Bring Your Own Key (BYOK) for use with
# your Sandbox Confluent Cloud Kafka Cluster, with giving your AWS account root minimal 
# "allow the account owner full control" permissions
resource "aws_kms_key" "byok" {
  description             = "KMS key for Confluent Cloud Kafka BYOK encryption in ${var.aws_region}"
  deletion_window_in_days = 14
  enable_key_rotation     = true
  policy                  = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "EnableRootAccountPermissions"
        Effect    = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action    = "kms:*"
        Resource  = "*"
      }
    ]
  })
}

# Creates a human-friendly alias for the KMS key created above, which is required for
# Confluent Cloud BYOK integration (i.e., you cannot use the KMS key's ARN directly,
# but must reference it via an alias)
resource "aws_kms_alias" "byok" {
  name          = "alias/confluent-cloud-byok-${var.kafka_cluster_name}"
  target_key_id = aws_kms_key.byok.key_id

  depends_on = [ 
    aws_kms_key.byok 
  ]
}

# Registers the AWS KMS key with Confluent Cloud 
resource "confluent_byok_key" "cluster" {
  aws {
    key_arn = aws_kms_key.byok.arn
  }

  depends_on = [ 
    aws_kms_alias.byok 
  ]
}

# This attaches the complete KMS key policy to the BYOK key, granting Confluent Cloud
# the permissions it needs to actually use the key for encryption
resource "aws_kms_key_policy" "byok" {
  key_id = aws_kms_key.byok.key_id
  policy  = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "EnableRootAccountPermissions"
        Effect    = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action    = "kms:*"
        Resource  = "*"
      },
      {
        Sid       = "AllowConfluentCloudBYOKAccess"
        Effect    = "Allow"
        Principal = {
          AWS = confluent_byok_key.cluster.aws[0].roles
        }
        Action    = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey",
        ]
        Resource  = "*"
      },
      {
        Sid       = "AllowConfluentCloudToAttachPersistentResources"
        Effect    = "Allow"
        Principal = {
          AWS = confluent_byok_key.cluster.aws[0].roles
        }
        Action    = [
          "kms:CreateGrant",
          "kms:ListGrants",
          "kms:RevokeGrant",
        ]
        Resource  = "*"
      }
    ]
  })

  depends_on = [ 
    confluent_byok_key.cluster
  ]
}
