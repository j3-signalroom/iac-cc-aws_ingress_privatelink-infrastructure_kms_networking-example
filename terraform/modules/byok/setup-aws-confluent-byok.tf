# Creates an AWS KMS key for Confluent Cloud BYOK encryption. The initial policy grants the AWS account
# root principal admin-only permissions (key management, no encrypt/decrypt). The full policy
# including Confluent's IAM role permissions is applied separately via aws_kms_key_policy once
# confluent_byok_key resolves the role ARNs
resource "aws_kms_key" "byok" {
  description             = "KMS key for Confluent Cloud Kafka BYOK encryption in ${var.aws_region}"
  deletion_window_in_days = var.deletion_window_days
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
        Action = [
          "kms:Create*",
          "kms:Describe*",
          "kms:Enable*",
          "kms:List*",
          "kms:Put*",
          "kms:Update*",
          "kms:Revoke*",
          "kms:Disable*",
          "kms:Get*",
          "kms:Delete*",
          "kms:ScheduleKeyDeletion",
          "kms:CancelKeyDeletion",
          "kms:TagResource",
          "kms:UntagResource"
        ]
        Resource  = "*"
      }
    ]
  })
}

# Creates a human-friendly alias for the KMS key created above
resource "aws_kms_alias" "byok" {
  name          = "alias/confluent-cloud-byok-${var.kafka_cluster_name}"
  target_key_id = aws_kms_key.byok.key_id
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

# Replaces the initial bootstrap policy with the full production policy, adding Confluent Cloud's 
# dynamically-provisioned IAM role ARNs which are only known after confluent_byok_key is registered
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
        Action = [
          "kms:Create*",
          "kms:Describe*",
          "kms:Enable*",
          "kms:List*",
          "kms:Put*",
          "kms:Update*",
          "kms:Revoke*",
          "kms:Disable*",
          "kms:Get*",
          "kms:Delete*",
          "kms:ScheduleKeyDeletion",
          "kms:CancelKeyDeletion",
          "kms:TagResource",
          "kms:UntagResource"
        ]
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
}
