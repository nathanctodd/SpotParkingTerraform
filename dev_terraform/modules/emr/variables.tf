variable "emr_service_role_arn" {
  description = "IAM role ARN used as the EMR service role"
  type        = string
}

variable "emr_instance_profile_arn" {
  description = "IAM instance profile ARN for EC2 nodes in EMR"
  type        = string
}