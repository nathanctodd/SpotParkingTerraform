terraform {
  backend "s3" {
    bucket         = "spotpark-terraform-state-bucket"
    key            = "spotdev/terraform.tfstate"  # acts like a file path in the bucket
    region         = "us-west-1"
    encrypt        = true                         # enable server-side encryption
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
