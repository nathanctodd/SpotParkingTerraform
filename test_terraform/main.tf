provider "aws" {
    region = "us-west-1"
    profile="spotprod"
}

# Development Account Materials

# S3 bucket for predictions
resource "aws_s3_bucket" "inferencing_predictions" {
    bucket = "inferencing-predictions"
}

#S3 for model artifacts
resource "aws_s3_bucket" "model_artifacts" {
    bucket = "model-artifacts"
}

# Create IAM Role for sagemaker instance
resource "aws_iam_role" "sagemaker_role" {
  name = "SageMakerExecutionRole"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "sagemaker.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

# Attach the AmazonSageMakerFullAccess policy to the role
resource "aws_iam_role_policy_attachment" "sagemaker_policy" {
  role       = aws_iam_role.sagemaker_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSageMakerFullAccess"
}

# Sagemaker Studio notebook
resource "aws_sagemaker_notebook_instance" "inferencing_notebook" {
    name = "inferencing-notebook"
    instance_type = "ml.t2.medium"
    role_arn = "arn:aws:iam::442426871585:role/service-role/AmazonSageMaker-ExecutionRole-20201231T123456"
}

# ECR Repository for the development system
resource "aws_ecr_repository" "inferencing_system" {
    name = "inferencing_system"
}

# IAM Role for the ECR repository
resource "aws_iam_role" "emr_service_role" {
  name = "AmazonElasticMapReduceServiceRole"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "elasticmapreduce.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "emr_service_role_policy" {
  role       = aws_iam_role.emr_service_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonElasticMapReduceRole"
}

# Amazon EMR
resource "aws_emr_cluster" "inferencing_cluster" {
    name = "inferencing_cluster"
    release_label = "emr-6.2.0"
    applications = ["Spark"]
    service_role = aws_iam_role.emr_service_role.arn
    configurations = <<EOF
{
    "Classification": "spark",
    "Properties": {
        "maximizeResourceAllocation": "true"
    }
}
EOF
}

# Amazon Step Functions
# Create IAM Role for Step Functions
resource "aws_iam_role" "step_functions_role" {
  name = "StepFunctionsRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "states.amazonaws.com"
        }
      }
    ]
  })
}

# Attach a policy to the IAM Role to allow Step Functions to invoke Lambda functions
resource "aws_iam_policy" "step_functions_lambda_invocation_policy" {
  name        = "StepFunctionsLambdaInvocationPolicy"
  description = "Policy to allow Step Functions to invoke Lambda functions"
  policy      = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "lambda:InvokeFunction",
        Effect = "Allow",
        Resource = "arn:aws:lambda:us-west-2:442426871585:function:inferencing_lambda"
      }
    ]
  })
}

# Attach the policy to the IAM Role
resource "aws_iam_role_policy_attachment" "attach_step_functions_lambda_invocation" {
  role       = aws_iam_role.step_functions_role.name
  policy_arn = aws_iam_policy.step_functions_lambda_invocation_policy.arn
}

# Create the AWS Step Functions State Machine
# resource "aws_sfn_state_machine" "inferencing_state_machine" {
#   name     = "inferencing_state_machine"
#   role_arn = aws_iam_role.step_functions_role.arn
#   definition = <<EOF
# {
#     "Comment": "A simple AWS Step Functions state machine that automates the inferencing process",
#     "StartAt": "Inferencing",
#     "States": {
#         "Inferencing": {
#             "Type": "Task",
#             "Resource": "arn:aws:lambda:us-west-2:442426871585:function:inferencing_lambda",
#             "End": true
#         }
#     }
# }
# EOF
# }



# Production Account Materials

# Creation of Star Command
resource "aws_instance" "star_command" {
    count         = 1
    ami           = "ami-0c55b159cbfafe1f0" # Replace with your desired AMI ID
    instance_type = "t2.micro"

    tags = {
        Name = "star_command"
    }
}

# Creation of Spock Inference System
resource "aws_instance" "spock_inference" {
    ami           = "ami-0c55b159cbfafe1f0" # Replace with your desired AMI ID
    instance_type = "c8g.1xlarge"

    tags = {
        Name = "example-spock_inference"
    }
}

# Creation of Kirk Event Manager System
resource "aws_instance" "kirk_event_manager" {
    ami           = "ami-0c55b159cbfafe1f0" # Replace with your desired AMI ID
    instance_type = "t3.small"

    tags = {
        Name = "kirk_event_manager"
    }
}

# Creation of SQS Queue into inferencing system
resource "aws_sqs_queue" "star_command_queue" {
    name = "star_command_queue"
    delay_seconds = 0
    message_retention_seconds = 86400
    visibility_timeout_seconds = 30
}

# Creation of SQS queue into event manager system
resource "aws_sqs_queue" "kirk_event_manager_queue" {
    name = "kirk_event_manager_queue"
    delay_seconds = 0
    message_retention_seconds = 86400
    visibility_timeout_seconds = 30
}

# Creation of S3 bucket for storing logs
resource "aws_s3_bucket" "star_command_video_storage" {
    bucket = "star-command-video-storage"
}

# Creation of DynamoDB table for storing predictions
resource "aws_dynamodb_table" "inferencing_predictions" {
    name           = "inferencing_predictions"
    billing_mode   = "PAY_PER_REQUEST"
    hash_key       = "video_id"  # Partition key

    # Define the attribute for the partition key
    attribute {
        name = "video_id"
        type = "S"  # String type for video_id
    }

    # Define the 'prediction' attribute
    attribute {
        name = "prediction"
        type = "S"  # String type for prediction
    }

    # Add a Global Secondary Index (GSI) on the 'prediction' attribute
    global_secondary_index {
        name               = "prediction-index"
        hash_key           = "prediction"
        projection_type    = "ALL"  # You can specify 'ALL', 'KEYS_ONLY', or 'INCLUDE' as the projection type
    }
}

# Creation of the ECR registry for the inferencing system
# resource "aws_ecr_repository" "inferencing_system" {
#     name = "inferencing_system"
# }


