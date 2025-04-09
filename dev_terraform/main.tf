module "s3" {
    source = "./modules/s3"
}

module "iam" {
    source = "./modules/iam"
}

module "sagemaker" {
    source = "./modules/sagemaker"
}

module "ecr" {
    source = "./modules/ecr"
}

module "emr" {
    source = "./modules/emr"
    emr_service_role_arn = module.iam.emr_service_role_arn
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
