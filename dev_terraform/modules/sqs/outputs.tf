output "voyager_tracking_queue_arn" {
    description = "ARN of the Voyager Tracking SQS queue"
    value       = aws_sqs_queue.voyager_tracking_queue.arn
}

output "kirk_event_manager_queue_arn" {
    description = "ARN of the Kirk Event Manager SQS queue"
    value       = aws_sqs_queue.kirk_event_manager_queue.arn
}