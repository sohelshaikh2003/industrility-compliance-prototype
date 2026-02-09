provider "aws" {
  region = var.aws_region
}

# We need a unique suffix because S3 bucket names are global.
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# --- COMPLIANT BUCKET ---
# This represents our secure production data store.
resource "aws_s3_bucket" "prod_data" {
  bucket = "industrility-secure-data-${random_id.bucket_suffix.hex}"

  tags = {
    Project     = var.project_name
    Compliance  = "SOC2"
    Environment = "Prod"
  }
}

# Strict access control. This should PASS our audit script.
resource "aws_s3_bucket_public_access_block" "prod_data_access" {
  bucket = aws_s3_bucket.prod_data.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# --- NON-COMPLIANT BUCKET ---
# Intentionally misconfigured to test our detection and alerting.
# In a real scenario, this might be a "shadow IT" bucket.
resource "aws_s3_bucket" "shadow_it_bucket" {
  bucket = "industrility-temp-logs-${random_id.bucket_suffix.hex}"

  tags = {
    Project    = var.project_name
    Security   = "Vulnerable"
    Note       = "Testing-Only"
  }
}

# Leaving this wide open (false) so the audit script triggers a FAIL.
resource "aws_s3_bucket_public_access_block" "shadow_it_access" {
  bucket = aws_s3_bucket.shadow_it_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}