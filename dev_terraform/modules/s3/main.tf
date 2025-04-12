resource "aws_s3_bucket" "inferencing_predictions" {
  bucket = "inferencing_predictions_spot"
}

resource "aws_s3_bucket" "model_artifacts" {
  bucket = "model_artifacts_spot"
}

resource "aws_s3_bucket" "star_command_video_storage" {
  bucket = "star_command_video_storage"
}
