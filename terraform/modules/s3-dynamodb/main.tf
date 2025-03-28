# Create the S3 Bucket for state storage
resource "aws_s3_bucket" "terraform_state" {
  bucket = var.s3_bucket_name

  lifecycle {
    prevent_destroy = true
  }

  tags = merge(var.tags, {
    "Name" = "Terraform State Bucket"
  })
}

resource "aws_s3_bucket_versioning" "versioning_example" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Create a DynamoDB Table for state locking
resource "aws_dynamodb_table" "terraform_locks" {
  name         = "terraform-state-lock"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = merge(var.tags, {
    "Name" = "Terraform State Lock Table"
  })
}
