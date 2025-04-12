output "star_command_instance_id" {
  description = "ID of the Star Command EC2 instance"
  value       = aws_instance.star_command_ec2.id
}

# output "spock_inference_instance_id" {
#   description = "ID of the Spock Inference EC2 instance"
#   value       = aws_instance.spock_inference.id
# }

# output "kirk_event_manager_instance_id" {
#   description = "ID of the Kirk Event Manager EC2 instance"
#   value       = aws_instance.kirk_event_manager.id
# }
