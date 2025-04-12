resource "aws_ecr_repository" "star_command" {
  name = "star_command"
}

resource "aws_ecr_repository" "inference_system" {
  name = "inference_system"
}

resource "aws_ecr_repository" "event_manager" {
  name = "event_manager"
}

resource "aws_ecr_lifecycle_policy" "star_command_policy" {
  repository = aws_ecr_repository.star_command.name

  policy = <<EOF
    {
        "rules": [
            {
                "rulePriority": 1,
                "description": "Keep only the last ${var.untagged_images} untagged images.",
                "selection": {
                    "tagStatus": "untagged",
                    "countType": "imageCountMoreThan",
                    "countNumber": ${var.untagged_images}
                },
                "action": {
                    "type": "expire"
                }
            }
        ]
    }
  EOF
}

resource "aws_ecr_lifecycle_policy" "inference_system_policy" {
  repository = aws_ecr_repository.inference_system.name

  policy = <<EOF
    {
        "rules": [
            {
                "rulePriority": 1,
                "description": "Keep only the last ${var.untagged_images} untagged images.",
                "selection": {
                    "tagStatus": "untagged",
                    "countType": "imageCountMoreThan",
                    "countNumber": ${var.untagged_images}
                },
                "action": {
                    "type": "expire"
                }
            }
        ]
    }
  EOF
}

resource "aws_ecr_lifecycle_policy" "event_manager_policy" {
  repository = aws_ecr_repository.event_manager.name

  policy = <<EOF
    {
        "rules": [
            {
                "rulePriority": 1,
                "description": "Keep only the last ${var.untagged_images} untagged images.",
                "selection": {
                    "tagStatus": "untagged",
                    "countType": "imageCountMoreThan",
                    "countNumber": ${var.untagged_images}
                },
                "action": {
                    "type": "expire"
                }
            }
        ]
    }
  EOF
}