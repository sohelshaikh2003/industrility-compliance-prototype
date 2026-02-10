# -----------------------------
# Random suffix for unique names
# -----------------------------
resource "random_id" "suffix" {
  byte_length = 4
}

# -----------------------------
# S3 bucket for SOC 2 evidence
# -----------------------------
resource "aws_s3_bucket" "evidence_bucket" {
  bucket = "soc2-evidence-${random_id.suffix.hex}"

  tags = {
    Compliance = "SOC2"
    Owner      = "AuditAutomation"
  }
}

# -----------------------------
# S3 bucket policy for CloudTrail
# -----------------------------
resource "aws_s3_bucket_policy" "cloudtrail_policy" {
  bucket = aws_s3_bucket.evidence_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSCloudTrailAclCheck"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.evidence_bucket.arn
      },
      {
        Sid    = "AWSCloudTrailWrite"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.evidence_bucket.arn}/AWSLogs/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}

# -----------------------------
# CloudTrail (SOC 2 Logging Control)
# -----------------------------
resource "aws_cloudtrail" "audit_trail" {
  name                          = "soc2-audit-trail"
  s3_bucket_name                = aws_s3_bucket.evidence_bucket.id
  include_global_service_events = true
  is_multi_region_trail         = true

  depends_on = [
    aws_s3_bucket_policy.cloudtrail_policy
  ]
}
