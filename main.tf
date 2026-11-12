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



# CHIFFREMENT (KMS CMK)
resource "aws_kms_key" "s3_key" {
  description             = "Clé KMS gérée par le client pour le bucket S3"
  deletion_window_in_days = 7
  enable_key_rotation     = true
}

# TRAÇABILITÉ (LOGGING BUCKET)
resource "aws_s3_bucket" "log_bucket" {
  bucket        = "logs-secu-cloud-576951332096"
  force_destroy = true
}

#  BUCKET PRINCIPAL SÉCURISÉ
resource "aws_s3_bucket" "mon_coffre_fort" {
  bucket        = "mon-projet-secu-cloud-12345"
  force_destroy = true
  
  tags = {
    Deploiement = "Via-GitHub-Actions"
  }
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

