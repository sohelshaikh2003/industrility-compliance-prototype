provider "aws" {
  region = var.aws_region
}

resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# COMPLIANT BUCKET
resource "aws_s3_bucket" "prod_data" {
  bucket = "${var.project_name}-secure-data-${random_id.bucket_suffix.hex}"

  tags = {
    Project     = var.project_name
    Compliance  = "SOC2"
  }
}

resource "aws_s3_bucket_public_access_block" "prod_data_access" {
  bucket = aws_s3_bucket.prod_data.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# NON-COMPLIANT BUCKET
resource "aws_s3_bucket" "shadow_it_bucket" {
  bucket = "${var.project_name}-temp-logs-${random_id.bucket_suffix.hex}"

  tags = {
    Project    = var.project_name
    Security   = "Vulnerable"
  }
}

resource "aws_s3_bucket_public_access_block" "shadow_it_access" {
  bucket = aws_s3_bucket.shadow_it_bucket.id

  block_public_acls       = false
  block_public_policy     = false
}