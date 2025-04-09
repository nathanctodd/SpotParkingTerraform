resource "aws_sagemaker_notebook_instance" "inferencing_notebook" {
    name = "inferencing-notebook"
    instance_type = "ml.t2.medium"
    role_arn = "arn:aws:iam::442426871585:role/service-role/AmazonSageMaker-ExecutionRole-20201231T123456"
}