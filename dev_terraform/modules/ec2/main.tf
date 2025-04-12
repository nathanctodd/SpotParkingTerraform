# Star Command
resource "aws_iam_role" "star_command_ec2_role" {
  name = "star_command_ec2_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_policy" "ec2_instance_connect_policy" {
  name        = "EC2InstanceConnectPolicy"
  description = "Policy to allow EC2 Instance Connect SSH access"
  policy      = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid: "EC2InstanceConnect",
        Effect   = "Allow"
        Action   = "ec2-instance-connect:SendSSHPublicKey"
        Resource = "*"
      },
      {
        Sid: "SSHPublicKey",
        Effect   = "Allow"
        Action   = "ec2-instance-connect:OpenTunnel"
        Resource = "*"
      },
      {
        Sid: "Describe",
        Effect   = "Allow"
        "Action": [
            "ec2:DescribeInstances",
            "ec2:DescribeInstanceConnectEndpoints"
        ],
        "Resource": "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "star_command_s3_access" {
  role       = aws_iam_role.star_command_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_iam_role_policy_attachment" "star_command_sqs_access" {
  role       = aws_iam_role.star_command_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSQSFullAccess"
}

resource "aws_iam_role_policy_attachment" "ec2_instance_connect_policy_attachment" {
  policy_arn = aws_iam_policy.ec2_instance_connect_policy.arn
  role       = aws_iam_role.star_command_ec2_role.name
}

resource "aws_iam_instance_profile" "star_command_ec2_profile" {
  name = "star_command_instance_profile"
  role = aws_iam_role.star_command_ec2_role.name
}

data "aws_caller_identity" "current" {}

resource "aws_instance" "star_command_ec2" {
  ami                    = "ami-067198c5ae913ba30" # Amazon Linux 2 AMI
  instance_type          = "t2.micro"
  iam_instance_profile   = aws_iam_instance_profile.star_command_ec2_profile.name

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              amazon-linux-extras install docker -y
              service docker start
              usermod -a -G docker ec2-user

              # Install AWS CLI v2
              curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
              unzip awscliv2.zip
              sudo ./aws/install

              # Log in to ECR
              $(aws ecr get-login-password --region ${var.aws_region} | docker login --username AWS --password-stdin ${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com)

              # Pull and run your Docker image
              docker pull ${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/${var.star_command_image_name}:latest
              docker run -d -p 80:80 ${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/${var.star_command_image_name}:latest
              EOF

  tags = {
    Name = "star_command"
  }
}

# Spock Inference

# resource "aws_instance" "spock_inference" {
#   ami           = "ami-020fbc00dbecba358"
#   instance_type = "m8g.large"

#   tags = {
#     Name = "example-spock_inference"
#   }
# }

# # Event Manager

# resource "aws_instance" "kirk_event_manager" {
#   ami           = "ami-020fbc00dbecba358"
#   instance_type = "t3.small"

#   tags = {
#     Name = "kirk_event_manager"
#   }
# }
