output "secure_bucket_id" {
  description = "The name of our compliant S3 bucket"
  value       = aws_s3_bucket.prod_data.id
}

output "vulnerable_bucket_id" {
  description = "The name of our non-compliant S3 bucket"
  value       = aws_s3_bucket.shadow_it_bucket.id
}