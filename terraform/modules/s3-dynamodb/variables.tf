# modules/ec2/variables.tf

variable "s3_bucket_name" {
  description = "The name of the S3 bucket for storing Terraform state"
  type        = string
}

variable "tags" {
  description = "A map of tags to assign to resources"
  type        = map(string)
}
