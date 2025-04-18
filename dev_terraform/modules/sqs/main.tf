# Creation of SQS Queue into inferencing system
resource "aws_sqs_queue" "voyager_tracking_queue" {
  name                       = "voyager-tracking-queue"
  delay_seconds              = 0
  message_retention_seconds  = 86400
  visibility_timeout_seconds = 30
  receive_wait_time_seconds = 20
  tags = {
    Name = "VoyagerTrackingQueue"
  }
}

# Creation of SQS queue into event manager system
resource "aws_sqs_queue" "kirk_event_manager_queue" {
  name                       = "kirk-event-managerqueue"
  delay_seconds              = 0
  message_retention_seconds  = 86400
  visibility_timeout_seconds = 30
  receive_wait_time_seconds = 20
  tags = {
    Name = "KirkEventManagerQueue"
  }
}

