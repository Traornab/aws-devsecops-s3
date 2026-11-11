terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "eu-north-1"
}

# 1. GESTION DES IDENTITÉS (ZERO TRUST OIDC)
resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["1b511abead59c6ce207077c0bf0e0043b1382612"] # Empreinte officielle GitHub
}

resource "aws_iam_role" "github_actions_role" {
  name = "github-actions-devsecops-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = { Federated = aws_iam_openid_connect_provider.github.arn },
      Action = "sts:AssumeRoleWithWebIdentity",
      Condition = {
        "StringLike" : {
          "token.actions.githubusercontent.com:sub" : "repo:Traornab/aws-devsecops-s3:*"
        }
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "github_actions_admin" {
  role       = aws_iam_role.github_actions_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# 2. CHIFFREMENT (KMS CMK)
resource "aws_kms_key" "s3_key" {
  description             = "Clé KMS gérée par le client pour le bucket S3"
  deletion_window_in_days = 7
  enable_key_rotation     = true
}

# 3. TRAÇABILITÉ (LOGGING BUCKET)
resource "aws_s3_bucket" "log_bucket" {
  bucket        = "logs-secu-cloud-576951332096"
  force_destroy = true
}

# 4. BUCKET PRINCIPAL SÉCURISÉ
resource "aws_s3_bucket" "mon_coffre_fort" {
  bucket        = "mon-projet-secu-cloud-12345"
  force_destroy = true
}

resource "aws_s3_bucket_logging" "bucket_logs" {
  bucket        = aws_s3_bucket.mon_coffre_fort.id
  target_bucket = aws_s3_bucket.log_bucket.id
  target_prefix = "acces-logs/"
}

resource "aws_s3_bucket_versioning" "storage_versioning" {
  bucket = aws_s3_bucket.mon_coffre_fort.id
  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "kms_encryption" {
  bucket = aws_s3_bucket.mon_coffre_fort.id
  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.s3_key.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "block_public" {
  bucket                  = aws_s3_bucket.mon_coffre_fort.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# 5. DÉTECTION DES FUITES (AMAZON MACIE)
resource "aws_macie2_account" "dlp_scanner" {
  finding_publishing_frequency = "FIFTEEN_MINUTES"
  status                       = "ENABLED"
}
