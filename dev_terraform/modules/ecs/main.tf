# resource "aws_vpc" "ecs_vpc" {
#   cidr_block           = "10.0.0.0/16"
#   enable_dns_support   = true
#   enable_dns_hostnames = true
  
#   tags = {
#     Name = "ecs-vpc"
#   }
# }

# resource "aws_subnet" "ecs_subnet_1" {
#   vpc_id                  = aws_vpc.ecs_vpc.id
#   cidr_block              = "10.0.1.0/24"
#   availability_zone       = "us-west-1a"
#   map_public_ip_on_launch = true
  
#   tags = {
#     Name = "ecs-subnet-1"
#   }
# }

# resource "aws_subnet" "ecs_subnet_2" {
#   vpc_id                  = aws_vpc.ecs_vpc.id
#   cidr_block              = "10.0.2.0/24"
#   availability_zone       = "us-west-1b"
#   map_public_ip_on_launch = true
  
#   tags = {
#     Name = "ecs-subnet-2"
#   }
# }

# # Security Group for ECS instances
# resource "aws_security_group" "ecs_sg" {
#   name        = "ecs-security-group"
#   description = "Security group for ECS instances"
#   vpc_id      = aws_vpc.ecs_vpc.id

#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   tags = {
#     Name = "ecs-sg"
#   }
# }

# # Internet Gateway
# resource "aws_internet_gateway" "igw" {
#   vpc_id = aws_vpc.ecs_vpc.id
  
#   tags = {
#     Name = "ecs-igw"
#   }
# }

# # Route Table
# resource "aws_route_table" "rt" {
#   vpc_id = aws_vpc.ecs_vpc.id
  
#   route {
#     cidr_block = "0.0.0.0/0"
#     gateway_id = aws_internet_gateway.igw.id
#   }
  
#   tags = {
#     Name = "ecs-rt"
#   }
# }

# resource "aws_route_table_association" "rta1" {
#   subnet_id      = aws_subnet.ecs_subnet_1.id
#   route_table_id = aws_route_table.rt.id
# }

# resource "aws_route_table_association" "rta2" {
#   subnet_id      = aws_subnet.ecs_subnet_2.id
#   route_table_id = aws_route_table.rt.id
# }

# # IAM stuff

# # ECS Instance Role
# resource "aws_iam_role" "ecs_instance_role" {
#   name = "ecsInstanceRole"
  
#   assume_role_policy = jsonencode({
#     Version = "2012-10-17",
#     Statement = [
#       {
#         Action = "sts:AssumeRole",
#         Effect = "Allow",
#         Principal = {
#           Service = "ec2.amazonaws.com"
#         }
#       }
#     ]
#   })
# }

# # Attach AmazonEC2ContainerServiceforEC2Role policy
# resource "aws_iam_role_policy_attachment" "ecs_instance_role_policy" {
#   role       = aws_iam_role.ecs_instance_role.name
#   policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
# }

# # Instance profile for EC2 instances
# resource "aws_iam_instance_profile" "ecs_instance_profile" {
#   name = "ecs-instance-profile"
#   role = aws_iam_role.ecs_instance_role.name
# }

# # ECS Task Execution Role
# resource "aws_iam_role" "ecs_task_execution_role" {
#   name = "ecsTaskExecutionRole"
  
#   assume_role_policy = jsonencode({
#     Version = "2012-10-17",
#     Statement = [
#       {
#         Action = "sts:AssumeRole",
#         Effect = "Allow",
#         Principal = {
#           Service = "ecs-tasks.amazonaws.com"
#         }
#       }
#     ]
#   })
# }

# # Attach the ECS task execution policy
# resource "aws_iam_role_policy_attachment" "ecs_task_execution_policy" {
#   role       = aws_iam_role.ecs_task_execution_role.name
#   policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
# }

# # Task Role - Allow containers to access AWS services
# resource "aws_iam_role" "ecs_task_role" {
#   name = "ecsTaskRole"
  
#   assume_role_policy = jsonencode({
#     Version = "2012-10-17",
#     Statement = [
#       {
#         Action = "sts:AssumeRole",
#         Effect = "Allow",
#         Principal = {
#           Service = "ecs-tasks.amazonaws.com"
#         }
#       }
#     ]
#   })
# }

# # Policy to allow access to SQS queues
# resource "aws_iam_policy" "sqs_access_policy" {
#   name        = "sqs-access-policy"
#   description = "Policy to allow ECS tasks to access SQS queues"
  
#   policy = jsonencode({
#     Version = "2012-10-17",
#     Statement = [
#       {
#         Effect = "Allow",
#         Action = [
#           "sqs:ReceiveMessage",
#           "sqs:DeleteMessage",
#           "sqs:GetQueueAttributes",
#           "sqs:SendMessage"
#         ],
#         Resource = [
#           var.star_command_queue_arn,
#           var.kirk_event_manager_queue_arn
#         ]
#       }
#     ]
#   })
# }

# # Attach SQS policy to task role
# resource "aws_iam_role_policy_attachment" "task_sqs_policy_attachment" {
#   role       = aws_iam_role.ecs_task_role.name
#   policy_arn = aws_iam_policy.sqs_access_policy.arn
# }

# # Cluster and Auto Scaling

# # ECS Cluster
# resource "aws_ecs_cluster" "ecs_cluster" {
#   name = "star-command-cluster"
  
#   setting {
#     name  = "containerInsights"
#     value = "enabled"
#   }
  
#   tags = {
#     Name = "StarCommandECSCluster"
#   }
# }

# # Launch Template for ECS Instances
# resource "aws_launch_template" "ecs_launch_template" {
#   name_prefix   = "ecs-launch-template-"
#   image_id      = "ami-067198c5ae913ba30"
#   instance_type = "t3.medium"
  
#   iam_instance_profile {
#     name = aws_iam_instance_profile.ecs_instance_profile.name
#   }
  
#   network_interfaces {
#     associate_public_ip_address = true
#     security_groups             = [aws_security_group.ecs_sg.id]
#   }
  
#   user_data = base64encode(<<-EOF
#     #!/bin/bash
#     echo "ECS_CLUSTER=${aws_ecs_cluster.ecs_cluster.name}" >> /etc/ecs/ecs.config
#     echo "ECS_ENABLE_CONTAINER_METADATA=true" >> /etc/ecs/ecs.config
#     EOF
#   )
  
#   tag_specifications {
#     resource_type = "instance"
#     tags = {
#       Name = "ECS-Instance"
#     }
#   }
# }

# # Auto Scaling Group for ECS Instances
# resource "aws_autoscaling_group" "ecs_asg" {
#   name                = "ecs-asg"
#   vpc_zone_identifier = [aws_subnet.ecs_subnet_1.id, aws_subnet.ecs_subnet_2.id]
#   min_size            = 1
#   max_size            = 10
#   desired_capacity    = 1
  
#   launch_template {
#     id      = aws_launch_template.ecs_launch_template.id
#     version = "$Latest"
#   }
  
#   tag {
#     key                 = "AmazonECSManaged"
#     value               = true
#     propagate_at_launch = true
#   }
# }

# # ECS Capacity Provider
# resource "aws_ecs_capacity_provider" "ecs_capacity_provider" {
#   name = "star-command-capacity-provider"
  
#   auto_scaling_group_provider {
#     auto_scaling_group_arn = aws_autoscaling_group.ecs_asg.arn
    
#     managed_scaling {
#       maximum_scaling_step_size = 5
#       minimum_scaling_step_size = 1
#       status                    = "ENABLED"
#       target_capacity           = 100
#     }
#   }
# }

# # Associate Capacity Provider with Cluster
# resource "aws_ecs_cluster_capacity_providers" "cluster_capacity_providers" {
#   cluster_name       = aws_ecs_cluster.ecs_cluster.name
#   capacity_providers = [aws_ecs_capacity_provider.ecs_capacity_provider.name]

#   default_capacity_provider_strategy {
#     capacity_provider = aws_ecs_capacity_provider.ecs_capacity_provider.name
#     weight            = 1
#   }
# }

# data "aws_caller_identity" "current" {}

# # ECS Task Definition
# resource "aws_ecs_task_definition" "task_definition" {
#   family                   = "star-command-task"
#   network_mode             = "bridge"
#   requires_compatibilities = ["EC2"]
#   execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
#   task_role_arn            = aws_iam_role.ecs_task_role.arn
#   cpu                      = "512"
#   memory                   = "1024"
  
#   container_definitions = jsonencode([
#     {
#       name      = "voyager_tracking"
#       image     = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/voyager-tracking:latest"
#       essential = true
      
#     #   environment = [
#     #     {
#     #       name  = "INPUT_QUEUE_URL",
#     #       value = aws_sqs_queue.input_queue.url
#     #     },
#     #     {
#     #       name  = "OUTPUT_QUEUE_URL",
#     #       value = aws_sqs_queue.output_queue.url
#     #     }
#     #   ],
      
#       logConfiguration = {
#         logDriver = "awslogs",
#         options = {
#           "awslogs-group"         = "/ecs/star-command-task",
#           "awslogs-region"        = "us-west-2",
#           "awslogs-stream-prefix" = "ecs"
#         }
#       }
#     }
#   ])
# }

# # CloudWatch Log Group for Container Logs
# resource "aws_cloudwatch_log_group" "ecs_logs" {
#   name              = "/ecs/star-command-task"
#   retention_in_days = 14
# }

# # ECS Service
# resource "aws_ecs_service" "ecs_service" {
#   name                               = "star-command-service"
#   cluster                            = aws_ecs_cluster.ecs_cluster.id
#   task_definition                    = aws_ecs_task_definition.task_definition.arn
#   desired_count                      = 1
#   deployment_minimum_healthy_percent = 50
#   deployment_maximum_percent         = 200
  
#   capacity_provider_strategy {
#     capacity_provider = aws_ecs_capacity_provider.ecs_capacity_provider.name
#     weight            = 1
#   }
# }
