variable "untagged_images" {
  description = "Number of untagged images to keep in the ECR repository"
  type        = number
  default     = 5
}

variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-west-1"
}

# resource "null_resource" "star_command_docker_packaging" {

# 	  provisioner "local-exec" {
# 	    command = <<EOF
# 	    aws ecr get-login-password --region ${var.aws_region} | docker login --username AWS --password-stdin ${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com
# 	    docker build -t "${aws_ecr_repository.star_command.repository_url}:latest" -f star_command/Dockerfile .
# 	    docker push "${aws_ecr_repository.star_command.repository_url}:latest"
# 	    EOF
# 	  }


# 	  triggers = {
# 	    "run_at" = timestamp()
# 	  }


# 	  depends_on = [
# 	    aws_ecr_repository.noiselesstech,
# 	  ]
# }