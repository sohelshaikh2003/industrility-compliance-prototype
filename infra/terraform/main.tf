# =============================================================================
# SOC 2 COMPLIANCE INFRASTRUCTURE PROTOTYPE
# Purpose: Automated Evidence Collection for CC7.2 and CC6.7
# =============================================================================

# -----------------------------------------------------------------------------
# 0. TERRAFORM CONFIGURATION & REMOTE BACKEND
# -----------------------------------------------------------------------------
terraform {
  backend "s3" {
    bucket         = "sohel-terraform-state-storage"
    key            = "soc2-prototype/terraform.tfstate"
    region         = "ap-south-1"
    encrypt        = true
  }
}

provider "aws" {
  region = "ap-south-1"
}

# -----------------------------------------------------------------------------
# 1. EVIDENCE STORAGE (S3)
# Hardcoded to your existing bucket to prevent "Destroy/Replace" actions.
# -----------------------------------------------------------------------------
resource "aws_s3_bucket" "evidence_bucket" {
  bucket = "soc2-evidence-09f775b8"

  tags = {
    Compliance  = "SOC2"
    Environment = "Prototype"
    Owner       = "SohelShaikh"
  }
}

# ENCRYPTION AT REST: Satisfies SOC 2 requirement for protecting data at rest.
resource "aws_s3_bucket_server_side_encryption_configuration" "evidence_encryption" {
  bucket = aws_s3_bucket.evidence_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# PUBLIC ACCESS BLOCK: Prevents accidental data exposure.
resource "aws_s3_bucket_public_access_block" "evidence_pab" {
  bucket = aws_s3_bucket.evidence_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# -----------------------------------------------------------------------------
# 2. ACCESS POLICIES
# -----------------------------------------------------------------------------
resource "aws_s3_bucket_policy" "cloudtrail_policy" {
  bucket = aws_s3_bucket.evidence_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSCloudTrailAclCheck"
        Effect = "Allow"
        Principal = { Service = "cloudtrail.amazonaws.com" }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.evidence_bucket.arn
      },
      {
        Sid    = "AWSCloudTrailWrite"
        Effect = "Allow"
        Principal = { Service = "cloudtrail.amazonaws.com" }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.evidence_bucket.arn}/AWSLogs/*"
        Condition = {
          StringEquals = { "s3:x-amz-acl" = "bucket-owner-full-control" }
        }
      }
    ]
  })
}

# -----------------------------------------------------------------------------
# 3. MONITORING & LOGGING (CLOUDWATCH + CLOUDTRAIL)
# -----------------------------------------------------------------------------
resource "aws_cloudwatch_log_group" "audit_logs" {
  name              = "/aws/cloudtrail/soc2-audit-trail"
  retention_in_days = 90
}

resource "aws_iam_role" "cloudtrail_to_cloudwatch" {
  name = "CloudTrailToCloudWatchRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "cloudtrail.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "cloudtrail_logs_policy" {
  name = "CloudTrailToCloudWatchPolicy"
  role = aws_iam_role.cloudtrail_to_cloudwatch.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = ["logs:CreateLogStream", "logs:PutLogEvents"]
      Resource = "${aws_cloudwatch_log_group.audit_logs.arn}:*"
    }]
  })
}

resource "aws_cloudtrail" "audit_trail" {
  name                          = "soc2-audit-trail"
  s3_bucket_name                = aws_s3_bucket.evidence_bucket.id
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_log_file_validation    = true 

  cloud_watch_logs_group_arn    = "${aws_cloudwatch_log_group.audit_logs.arn}:*" 
  cloud_watch_logs_role_arn     = aws_iam_role.cloudtrail_to_cloudwatch.arn

  depends_on = [aws_s3_bucket_policy.cloudtrail_policy]
}