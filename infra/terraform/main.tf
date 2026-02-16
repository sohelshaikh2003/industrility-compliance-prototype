# =============================================================================
# SOC 2 COMPLIANCE INFRASTRUCTURE PROTOTYPE
# Purpose: Automated Evidence Collection for CC7.2 (Monitoring) and CC6.7 (Data Protection)
# =============================================================================

# -----------------------------------------------------------------------------
# 0. TERRAFORM CONFIGURATION & REMOTE BACKEND
# Stores the infrastructure state in S3 to prevent resource duplication.
# -----------------------------------------------------------------------------
terraform {
  backend "s3" {
    bucket         = "sohel-terraform-state-storage"
    key            = "soc2-prototype/terraform.tfstate"
    region         = "ap-south-1"
    encrypt        = true
    # Optional: dynamodb_table = "terraform-lock" (to prevent concurrent runs)
  }
}

provider "aws" {
  region = "ap-south-1"
}

# -----------------------------------------------------------------------------
# 1. RESOURCE IDENTIFICATION
# Generates a unique hexadecimal suffix to prevent naming collisions in S3.
# -----------------------------------------------------------------------------
resource "aws_s3_bucket" "evidence_bucket" {
  bucket = "soc2-evidence-09f775b8" # Remove the ${random_id.suffix.hex}
}

# -----------------------------------------------------------------------------
# 2. EVIDENCE STORAGE (S3)
# Primary repository for audit logs and compliance artifacts.
# -----------------------------------------------------------------------------
resource "aws_s3_bucket" "evidence_bucket" {
  bucket = "soc2-evidence-${random_id.suffix.hex}"

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

# PUBLIC ACCESS BLOCK: Prevents accidental data exposure (Logical Access Control).
resource "aws_s3_bucket_public_access_block" "evidence_pab" {
  bucket = aws_s3_bucket.evidence_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# -----------------------------------------------------------------------------
# 3. ACCESS POLICIES
# Grants AWS CloudTrail permission to write audit logs to the S3 bucket.
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
# 4. REAL-TIME MONITORING (CLOUDWATCH)
# Enables immediate visibility into account activity via log streaming.
# -----------------------------------------------------------------------------
resource "aws_cloudwatch_log_group" "audit_logs" {
  name              = "/aws/cloudtrail/soc2-audit-trail"
  retention_in_days = 90 # Retention policy aligned with audit cycles
}

# IAM ROLE: Allows CloudTrail to assume a role to deliver logs to CloudWatch.
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

# IAM POLICY: Specifically grants the ability to stream events and create log streams.
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

# -----------------------------------------------------------------------------
# 5. AUDIT TRAIL (CLOUDTRAIL)
# The "Source of Truth" for all account activity.
# -----------------------------------------------------------------------------
resource "aws_cloudtrail" "audit_trail" {
  name                          = "soc2-audit-trail"
  s3_bucket_name                = aws_s3_bucket.evidence_bucket.id
  include_global_service_events = true
  is_multi_region_trail         = true
  
  # LOG FILE VALIDATION: Essential for non-repudiation (proof logs haven't been edited).
  enable_log_file_validation    = true 

  # INTEGRATION: Connects the trail to CloudWatch for active alerting.
  cloud_watch_logs_group_arn    = "${aws_cloudwatch_log_group.audit_logs.arn}:*" 
  cloud_watch_logs_role_arn     = aws_iam_role.cloudtrail_to_cloudwatch.arn

  depends_on = [aws_s3_bucket_policy.cloudtrail_policy]
}