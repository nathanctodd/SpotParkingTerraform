resource "aws_sagemaker_notebook_instance" "inferencing_notebook" {
    name = "inferencing-notebook"
    instance_type = "ml.t2.medium"
    role_arn = var.role_arn
}