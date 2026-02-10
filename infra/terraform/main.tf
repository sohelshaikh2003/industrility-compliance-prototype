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
# CloudTrail (SOC 2 Logging Control)
# -----------------------------
resource "aws_cloudtrail" "audit_trail" {
  name                          = "soc2-audit-trail"
  s3_bucket_name                = aws_s3_bucket.evidence_bucket.id
  include_global_service_events = true
  is_multi_region_trail         = true
}
