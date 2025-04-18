output "star_command_image_url" {
    description = "URL of the Star Command ECR image"
    value       = aws_ecr_repository.star_command.repository_url
}