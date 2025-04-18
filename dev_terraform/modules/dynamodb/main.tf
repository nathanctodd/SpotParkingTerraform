resource "aws_dynamodb_table" "inferencing_predictions" {
  name         = "inferencing_predictions"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "video_id"

  attribute {
    name = "video_id"
    type = "S"
  }

  attribute {
    name = "prediction"
    type = "S"
  }

  global_secondary_index {
    name            = "prediction-index"
    hash_key        = "prediction"
    projection_type = "ALL"
  }
}