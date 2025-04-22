# Star Command

# Auto scaling notes:
# - Star Command (80%): Set rules to be CPU based (80%)
# - Spock Inference: Set rules to be CPU based
# - Event Manager: Just 1 EC2 instance (Consider scaling up/down based on load)

# Network access including SSH and HTTP/HTTPS for FastAPI
resource "aws_security_group" "star_command_network_access" {
  name        = "star_command_ssh"
  description = "Allow SSH and FastAPI access from anywhere"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # SSH from anywhere (not recommended for production)
  }

  ingress {
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # HTTP (FastAPI on port 80)
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # HTTPS (if you use SSL)
  }

  # If your FastAPI runs on a custom port (e.g., 8000 or 5000), add:
  ingress {
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "tls_private_key" "star_command_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "star_command_kp" {
  key_name   = "star_command_key"
  public_key = tls_private_key.star_command_key.public_key_openssh
}

resource "local_file" "star_command_private_key" {
  content         = tls_private_key.star_command_key.private_key_pem
  filename        = "star_command.pem"
  file_permission = "0400"
}

# AWS permissions

resource "aws_iam_role" "ec2_role" {
  name = "ec2_role"

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
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid : "EC2InstanceConnect",
        Effect   = "Allow"
        Action   = "ec2-instance-connect:SendSSHPublicKey"
        Resource = "*"
      },
      {
        Sid : "SSHPublicKey",
        Effect   = "Allow"
        Action   = "ec2-instance-connect:OpenTunnel"
        Resource = "*"
      },
      {
        Sid : "Describe",
        Effect = "Allow"
        "Action" : [
          "ec2:DescribeInstances",
          "ec2:DescribeInstanceConnectEndpoints"
        ],
        "Resource" : "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "star_command_s3_access" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_iam_role_policy_attachment" "star_command_sqs_access" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSQSFullAccess"
}

resource "aws_iam_role_policy_attachment" "star_command_ec2_instance_connect_policy_attachment" {
  policy_arn = aws_iam_policy.ec2_instance_connect_policy.arn
  role       = aws_iam_role.ec2_role.name
}

resource "aws_iam_role_policy_attachment" "star_command_ecr_access" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "star_command_cloudwatch_logs" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_role_policy_attachment" "star_command_cloudwatch_full" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
}

resource "aws_iam_instance_profile" "star_command_ec2_profile" {
  name = "star_command_instance_profile"
  role = aws_iam_role.ec2_role.name
}

data "aws_caller_identity" "current" {}

resource "aws_instance" "star_command_ec2" {
  ami                    = "ami-067198c5ae913ba30" # Amazon Linux 2 AMI
  instance_type          = "t2.micro"
  iam_instance_profile   = aws_iam_instance_profile.star_command_ec2_profile.name
  key_name               = aws_key_pair.star_command_kp.key_name
  vpc_security_group_ids = [aws_security_group.star_command_network_access.id]

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
              docker run -d \
                --log-driver=awslogs \
                --log-opt awslogs-region=${var.aws_region} \
                --log-opt awslogs-group=/ec2/star-command \
                --log-opt awslogs-stream=star-command-$(hostname) \
                --log-opt awslogs-create-group=true \
                -p 80:8000 \
                ${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/${var.star_command_image_name}:latest
              EOF

  tags = {
    Name = "star_command"
  }
}

# Voyager Tracking

# Network access including SSH and HTTP/HTTPS for FastAPI
resource "aws_security_group" "voyager_tracking_network_access" {
  name        = "voyager_tracking_ssh"
  description = "Allow SSH and FastAPI access from anywhere"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # SSH from anywhere (not recommended for production)
  }

  ingress {
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # HTTP (FastAPI on port 80)
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # HTTPS (if you use SSL)
  }

  # If your FastAPI runs on a custom port (e.g., 8000 or 5000), add:
  ingress {
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "tls_private_key" "voyager_tracking_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "voyager_tracking_kp" {
  key_name   = "voyager_tracking_key"
  public_key = tls_private_key.voyager_tracking_key.public_key_openssh
}

resource "local_file" "voyager_tracking_private_key" {
  content         = tls_private_key.voyager_tracking_key.private_key_pem
  filename        = "voyager_tracking.pem"
  file_permission = "0400"
}

# AWS permissions

resource "aws_iam_role_policy_attachment" "voyager_tracking_s3_access" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_iam_role_policy_attachment" "voyager_tracking_sqs_access" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSQSFullAccess"
  
}

resource "aws_iam_role_policy_attachment" "voyager_tracking_sagemaker_access" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSageMakerFullAccess"
}

resource "aws_iam_role_policy_attachment" "voyager_tracking_ec2_instance_connect_policy_attachment" {
  policy_arn = aws_iam_policy.ec2_instance_connect_policy.arn
  role       = aws_iam_role.ec2_role.name
}

resource "aws_iam_role_policy_attachment" "voyager_tracking_ecr_access" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_instance_profile" "voyager_tracking_ec2_profile" {
  name = "voyager_tracking_instance_profile"
  role = aws_iam_role.ec2_role.name
}

resource "aws_iam_role_policy_attachment" "voyager_tracking_cloudwatch_logs" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_role_policy_attachment" "voyager_tracking_cloudwatch_full" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
}

resource "aws_instance" "voyager_tracking_ec2" {
  ami                    = "ami-067198c5ae913ba30" # Amazon Linux 2 AMI
  instance_type          = "t2.micro" # Change to bigger instance type if needed
  iam_instance_profile   = aws_iam_instance_profile.voyager_tracking_ec2_profile.name
  key_name               = aws_key_pair.voyager_tracking_kp.key_name
  vpc_security_group_ids = [aws_security_group.star_command_network_access.id]

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
              docker pull ${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/${var.voyager_tracking_image_name}:latest
              docker run -d \
                --log-driver=awslogs \
                --log-opt awslogs-region=${var.aws_region} \
                --log-opt awslogs-group=/ec2/voyager-tracking \
                --log-opt awslogs-stream=voyager-tracking-$(hostname) \
                --log-opt awslogs-create-group=true \
                -p 80:8000 \
                ${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/${var.voyager_tracking_image_name}:latest
              EOF

  tags = {
    Name = "voyager_tracking"
  }
}


# Kirk Event Manager

resource "aws_security_group" "kirk_event_manager_network_access" {
  name        = "kirk_event_manager_ssh"
  description = "Allow SSH and FastAPI access from anywhere"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # SSH from anywhere (not recommended for production)
  }

  ingress {
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # HTTP (FastAPI on port 80)
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # HTTPS (if you use SSL)
  }

  # If your FastAPI runs on a custom port (e.g., 8000 or 5000), add:
  ingress {
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "tls_private_key" "kirk_event_manager_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "kirk_event_manager_kp" {
  key_name   = "kirk_event_manager_key"
  public_key = tls_private_key.kirk_event_manager_key.public_key_openssh
}

resource "local_file" "kirk_event_manager_private_key" {
  content         = tls_private_key.kirk_event_manager_key.private_key_pem
  filename        = "kirk_event_manager.pem"
  file_permission = "0400"
}

# AWS permissions

resource "aws_iam_role_policy_attachment" "kirk_event_manager_s3_access" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_iam_role_policy_attachment" "kirk_event_manager_sqs_access" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSQSFullAccess"
}

resource "aws_iam_role_policy_attachment" "kirk_event_manager_ec2_instance_connect_policy_attachment" {
  policy_arn = aws_iam_policy.ec2_instance_connect_policy.arn
  role       = aws_iam_role.ec2_role.name
}

resource "aws_iam_role_policy_attachment" "kirk_event_manager_ecr_access" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "kirk_event_manager_cloudwatch_logs" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_role_policy_attachment" "kirk_event_manager_cloudwatch_full" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
}

resource "aws_iam_instance_profile" "kirk_event_manager_ec2_profile" {
  name = "kirk_event_manager_instance_profile"
  role = aws_iam_role.ec2_role.name
}

resource "aws_instance" "kirk_event_manager_ec2" {
  ami                    = "ami-067198c5ae913ba30" # Amazon Linux 2 AMI
  instance_type          = "t2.micro"
  iam_instance_profile   = aws_iam_instance_profile.kirk_event_manager_ec2_profile.name
  key_name               = aws_key_pair.kirk_event_manager_kp.key_name
  vpc_security_group_ids = [aws_security_group.kirk_event_manager_network_access.id]

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
              docker pull ${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/${var.kirk_event_manager_image_name}:latest
              docker run -d \
                --log-driver=awslogs \
                --log-opt awslogs-region=${var.aws_region} \
                --log-opt awslogs-group=/ec2/kirk-event-manager \
                --log-opt awslogs-stream=kirk-event-manager-$(hostname) \
                --log-opt awslogs-create-group=true \
                -p 80:8000 \
                ${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/${var.kirk_event_manager_image_name}:latest
              EOF

  tags = {
    Name = "kirk_event_manager"
  }
}

# Add DynamoDB write access policy
resource "aws_iam_policy" "kirk_event_manager_dynamodb" {
  name        = "KirkEventManagerDynamoDBWrite"
  description = "Allow write access to DynamoDB `event` table"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "DynamoDBWriteAccess",
        Effect = "Allow",
        Action = [
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:BatchWriteItem",
          "dynamodb:DeleteItem"
        ],
        Resource = [
          "arn:aws:dynamodb:${var.aws_region}:${data.aws_caller_identity.current.account_id}:table/events", // TODO: Replace `events` with TF ouput from dyanmodb module
          "arn:aws:dynamodb:${var.aws_region}:${data.aws_caller_identity.current.account_id}:table/events/index/*"
        ]
      },
      {
        Sid    = "DynamoDBDescribeTable",
        Effect = "Allow",
        Action = "dynamodb:DescribeTable",
        Resource = "arn:aws:dynamodb:${var.aws_region}:${data.aws_caller_identity.current.account_id}:table/events"
      }
    ]
  })
}

# Attach policy to existing EC2 role
resource "aws_iam_role_policy_attachment" "kirk_event_manager_dynamodb" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.kirk_event_manager_dynamodb.arn
}


# CloudWatch Logs

resource "aws_cloudwatch_log_group" "star_command" {
  name = "/ec2/star_command"
}

resource "aws_cloudwatch_log_group" "voyager_tracking" {
  name = "/ec2/voyager_tracking"
}

resource "aws_cloudwatch_log_group" "kirk_event_manager" {
  name = "/ec2/kirk_event_manager"
}