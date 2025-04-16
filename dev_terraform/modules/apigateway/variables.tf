variable "aws_region" {
  description = "The AWS region where resources will be created"
  type        = string
  default     = "us-west-1"
}

variable "star_command_ec2_public_ip" {
  description = "Public IP address of the Star Command EC2 instance"
  type        = string
}