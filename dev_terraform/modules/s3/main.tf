resource "aws_s3_bucket" "inferencing_predictions" {
  bucket = "inferencing-predictions-spot"
}

resource "aws_s3_bucket" "star_command_video_storage" {
  bucket = "star-command-video-storage"
  force_destroy = true
}

resource "aws_s3_bucket" "model_artifacts" {
  bucket = "model-artifacts-spot"
}