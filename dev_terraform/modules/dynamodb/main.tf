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

resource "aws_dynamodb_table" "events" {
  name         = "events"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "camera"
  range_key    = "timestamp"

  attribute {
    name = "camera"
    type = "S"
  }

  attribute {
    name = "timestamp"
    type = "S"
  }

  attribute {
    name = "date"
    type = "S"
  }

  global_secondary_index {
    name            = "date-index"
    hash_key        = "date"
    range_key       = "timestamp"
    projection_type = "ALL"
  }

  tags = {
    Name = "Events Table"
  }
}
