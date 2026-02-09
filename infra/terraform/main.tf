provider "aws" {
  region = "ap-south-1" # Mumbai Region
}

# 1. COMPLIANT BUCKET (Encrypted & Private)
resource "aws_s3_bucket" "compliant_bucket" {
  bucket = "industrility-compliant-mumbai-${random_id.suffix.hex}"
}

resource "aws_s3_bucket_public_access_block" "compliant_block" {
  bucket = aws_s3_bucket.compliant_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# 2. NON-COMPLIANT BUCKET (Public Access - The Audit Failure)
resource "aws_s3_bucket" "vulnerable_bucket" {
  bucket = "industrility-danger-mumbai-${random_id.suffix.hex}"
}

# We deliberately omit the "block_public_access" configuration here 
# to simulate a compliance violation for the prototype.

resource "random_id" "suffix" {
  byte_length = 4
}