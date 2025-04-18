# Creation of SQS Queue into inferencing system
resource "aws_sqs_queue" "star_command_queue" {
  name                       = "star_command_queue"
  delay_seconds              = 0
  message_retention_seconds  = 86400
  visibility_timeout_seconds = 30
}

# Creation of SQS queue into event manager system
resource "aws_sqs_queue" "kirk_event_manager_queue" {
  name                       = "kirk_event_manager_queue"
  delay_seconds              = 0
  message_retention_seconds  = 86400
  visibility_timeout_seconds = 30
}

