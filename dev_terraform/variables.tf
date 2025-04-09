variable "aws_region" {
  description = "AWS region to deploy resources"
  default     = "us-west-1"
}

variable "aws_profile" {
  description = "AWS CLI profile to use for authentication"
  type        = string
}