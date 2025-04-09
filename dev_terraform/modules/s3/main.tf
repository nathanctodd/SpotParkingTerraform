resource "aws_s3_bucket" "inferencing_predictions" {
  bucket = "inferencing-predictions"
}

resource "aws_s3_bucket" "model_artifacts" {
  bucket = "model-artifacts"
}

resource "aws_s3_bucket" "star_command_video_storage" {
  bucket = "star-command-video-storage"
}
