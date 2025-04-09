output "emr_service_role_arn" {
  description = "ARN of the EMR service role"
  value       = aws_iam_role.emr_service_role.arn
}

output "sagemaker_role_arn" {
  description = "ARN of the SageMaker execution role"
  value       = aws_iam_role.sagemaker_role.arn
}