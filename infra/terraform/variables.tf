variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "compliant_bucket_name" {
  type    = string
  default = "sohel-soc2-private-data"
}

variable "non_compliant_bucket_name" {
  type    = string
  default = "sohel-soc2-public-leak"
}