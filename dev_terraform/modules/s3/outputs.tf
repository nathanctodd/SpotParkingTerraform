output "inferencing_predictions_bucket" {
  description = "Name of the predictions S3 bucket"
  value       = aws_s3_bucket.inferencing_predictions.bucket
}

output "model_artifacts_bucket" {
  description = "Name of the model artifacts S3 bucket"
  value       = aws_s3_bucket.model_artifacts.bucket
}

output "star_command_video_storage_bucket_name" {
  description = "Name of the video storage S3 bucket"
  value       = aws_s3_bucket.star_command_video_storage.bucket
}
