# The region where all resources will live. 
# Defaulting to Mumbai as discussed for the prototype.
variable "aws_region" {
  type    = string
  default = "ap-south-1"
}

# Used for tagging resources so we can find them in the billing console.
variable "project_name" {
  type    = string
  default = "industrility-soc2-demo"
}