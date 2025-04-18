variable "star_command_video_storage_bucket_name" {
  description = "Name of the S3 bucket for Star Command video storage"
  type        = string
  default     = "star_command_video_storage"
}

variable "aws_region" {
  description = "The AWS region where resources will be created"
  type        = string
  default     = "us-west-1"
}

variable "star_command_image_name" {
  description = "The name of the Docker image to be used in the EC2 instance"
  type        = string
  default     = "star-command"
}