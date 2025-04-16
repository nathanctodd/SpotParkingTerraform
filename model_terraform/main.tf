variable "model_registry_name" {
  description = "Name of the S3 bucket to use as the model registry"
  type        = string
}

resource "aws_s3_bucket" "model_registry" {
  bucket = var.model_registry_name

  tags = {
    Name        = var.model_registry_name
    Environment = "ml-model-registry"
  }
}

resource "aws_s3_bucket_public_access_block" "model_registry_block" {
  bucket = aws_s3_bucket.model_registry.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "model_registry_versioning" {
  bucket = aws_s3_bucket.model_registry.id

  versioning_configuration {
    status = "Enabled"
  }
}