output "config_rule_name" {
  value = aws_config_config_rule.s3_public_read.name
}

output "compliant_bucket" {
  value = aws_s3_bucket.compliant_storage.id
}