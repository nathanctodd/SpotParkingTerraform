# Create a DynamoDB table for Terraform state locking
resource "aws_dynamodb_table" "terraform_state_lock" {
  name         = "terraform-state-lock"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name = "Terraform State Lock Table"
  }
}

terraform {
  backend "s3" {
    bucket         = "spotpark-terraform-state-bucket"
    key            = "spotdev/terraform.tfstate" # acts like a file path in the bucket
    region         = "us-west-1"
    encrypt        = true # enable server-side encryption
    dynamodb_table = "terraform-state-lock" # use DynamoDB for state locking
  }
}

module "s3" {
  source = "./modules/s3"
}

module "iam" {
  source = "./modules/iam"
}

module "sagemaker" {
  source   = "./modules/sagemaker"
  role_arn = module.iam.sagemaker_role_arn
}

module "ecr" {
  source = "./modules/ecr"
}

module "emr" {
  source = "./modules/emr"

  emr_service_role_arn     = module.iam.emr_service_role_arn
  emr_instance_profile_arn = module.iam.emr_instance_profile_arn
}

module "ec2" {
  source = "./modules/ec2"
}

module "sqs" {
  source = "./modules/sqs"
}

module "dynamodb" {
  source = "./modules/dynamodb"
}

module "apigateway" {
  source                     = "./modules/apigateway"
  star_command_ec2_public_ip = module.ec2.star_command_ec2_public_ip
}

# TODO: Uncomment and configure the ECS module when ready
# module "ecs" {
#   source = "./modules/ecs"
#   aws_region                = "us-west-1"
#   star_command_queue_arn    = module.sqs.star_command_queue_arn
#   kirk_event_manager_queue_arn = module.sqs.kirk_event_manager_queue_arn
# }

output "star_command_instance_public_ip" {
  description = "Public IP of the Star Command EC2 instance"
  value       = module.ec2.star_command_ec2_public_ip
}

output "voyager_tracking_instance_public_ip" {
  description = "Public IP of the Voyager Tracking EC2 instance"
  value       = module.ec2.voyager_tracking_ec2_public_ip
}

output "beam_me_sentry_api_gateway_url" {
  description = "API Gateway URL for Beam Me Sentry"
  value       = module.apigateway.beam_me_sentry_api_gateway_url
}