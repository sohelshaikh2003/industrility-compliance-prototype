# 1. Compliant Bucket
resource "aws_s3_bucket" "compliant_storage" {
  bucket = var.compliant_bucket_name
}

resource "aws_s3_bucket_public_access_block" "compliant_block" {
  bucket = aws_s3_bucket.compliant_storage.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# 2. Non-Compliant Bucket (No public block)
resource "aws_s3_bucket" "leaked_storage" {
  bucket = var.non_compliant_bucket_name
}

# 3. AWS Config Setup
resource "aws_iam_role" "config_role" {
  name = "sohel-aws-config-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "config.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "config_policy" {
  role       = aws_iam_role.config_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWS_ConfigRole"
}

resource "aws_config_configuration_recorder" "main" {
  name     = "soc2-recorder"
  role_arn = aws_iam_role.config_role.arn
}

resource "aws_config_configuration_recorder_status" "main" {
  name       = aws_config_configuration_recorder.main.name
  is_enabled = true
}

resource "aws_config_config_rule" "s3_public_read" {
  name = "s3-bucket-public-read-prohibited"
  source {
    owner             = "AWS"
    source_identifier = "S3_BUCKET_PUBLIC_READ_PROHIBITED"
  }
  depends_on = [aws_config_configuration_recorder.main]
}