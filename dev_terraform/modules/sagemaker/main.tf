resource "aws_s3_bucket" "model_artifacts" {
  bucket        = "spot-model-artifacts-${random_id.suffix.hex}"
  force_destroy = true
}

resource "random_id" "suffix" {
  byte_length = 4
}

resource "aws_sagemaker_model_package_group" "spot-model-registry" {
  model_package_group_name        = "spot-model-registry"
  model_package_group_description = "Model registry for vehicle detection, license plate detection, and license plate rectification models"
  tags = {
    environment = "dev"
  }
}

# Create IAM role for SageMaker execution
resource "aws_iam_role" "sagemaker_execution_role" {
  name = "sagemaker-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "sagemaker.amazonaws.com"
        }
      }
    ]
  })
}

# Attach necessary policies to the role
resource "aws_iam_role_policy_attachment" "sagemaker_full_access" {
  role       = aws_iam_role.sagemaker_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSageMakerFullAccess"
}

# Reference your ECR repositories
data "aws_ecr_repository" "lpr_detect" {
  name = "lpr-detect"
}

data "aws_ecr_repository" "car_detect" {
  name = "car-detect"
}

# Create model for license plate detection
resource "aws_sagemaker_model" "lpr_detect_model" {
  name               = "lpr-detect-model"
  execution_role_arn = aws_iam_role.sagemaker_execution_role.arn

  primary_container {
    image = "${data.aws_ecr_repository.lpr_detect.repository_url}@sha256:d7c908de99d492f6f9f28cd04624cb58a0822e29effc2a4347eba703f5532ddb"
    # If your model is contained in the Docker image, you don't need model_data_url
  }

  tags = {
    ModelPackageGroupName = aws_sagemaker_model_package_group.spot-model-registry.model_package_group_name
    environment           = "dev"
    repository            = "lpr-detect"
  }
}

# Create model for car detection
resource "aws_sagemaker_model" "car_detect_model" {
  name               = "car-detect-model"
  execution_role_arn = aws_iam_role.sagemaker_execution_role.arn

  primary_container {
    image = "${data.aws_ecr_repository.car_detect.repository_url}@sha256:6409f43c09494846d56d90cc4df221a624bf8f5bbb9cedbc8a69fe1aad137949"
    # If your model is contained in the Docker image, you don't need model_data_url
  }

  tags = {
    ModelPackageGroupName = aws_sagemaker_model_package_group.spot-model-registry.model_package_group_name
    environment           = "dev"
    repository            = "car-detect"
  }
}



#resource "aws_sagemaker_notebook_instance" "inferencing_notebook" {
#    name = "inferencing-notebook"
#    instance_type = "ml.t2.medium"
#    role_arn = var.role_arn
#}

# # Models for AWS Sagemaker
# resource "aws_sagemaker_model" "car-detection-model" {
#   name                  = "car-detection-model"
#   execution_role_arn    = var.role_arn
#   primary_container {
#     image               = "123456789012.dkr.ecr.us-west-1.amazonaws.com/spotpark-model:latest" # Replace with your actual image URI
#     model_data_url      = "s3://spotpark-model-artifacts/model.tar.gz" # Replace with your actual model artifact path
#   }
# }

# resource "aws_sagemaker_model" "license-plate-detection-model" {
#   name                  = "license-plate-detection-model"
#   execution_role_arn    = var.role_arn
#   primary_container {
#     image               = "123456789012.dkr.ecr.us-west-1.amazonaws.com/spotpark-model:latest" # Replace with your actual image URI
#     model_data_url      = "s3://spotpark-model-artifacts/model.tar.gz" # Replace with your actual model artifact path
#   }
# }

# resource "aws_sagemaker_model" "license-plate-rectification-model" {
#   name                  = "license-plate-rectification-model"
#   execution_role_arn    = var.role_arn
#   primary_container {
#     image               = "123456789012.dkr.ecr.us-west-1.amazonaws.com/spotpark-model:latest" # Replace with your actual image URI
#     model_data_url      = "s3://spotpark-model-artifacts/model.tar.gz" # Replace with your actual model artifact path
#   }
# }


# #Endpoint configurations
# resource "aws_sagemaker_endpoint_configuration" "car_detection_model_endpoint_config" {
#   name = "car-detection-model-endpoint-config"
#   production_variants {
#     variant_name           = "car-detection-variant"
#     model_name             = aws_sagemaker_model.car-detection-model.name
#     initial_instance_count = 1
#     instance_type          = "ml.t2.medium"
#   }
# }

# resource "aws_sagemaker_endpoint_configuration" "license_plate_detection_model_endpoint_config" {
#   name = "license-plate-detection-model-endpoint-config"
#   production_variants {
#     variant_name           = "license-plate-detection-variant"
#     model_name             = aws_sagemaker_model.license-plate-detection-model.name
#     initial_instance_count = 1
#     instance_type          = "ml.t2.medium"
#   }
# }

# resource "aws_sagemaker_endpoint_configuration" "license_plate_rectification_model_endpoint_config" {
#   name = "license-plate-rectification-model-endpoint-config"
#   production_variants {
#     variant_name           = "license-plate-rectification-variant"
#     model_name             = aws_sagemaker_model.license-plate-rectification-model.name
#     initial_instance_count = 1
#     instance_type          = "ml.t2.medium"
#   }
# }


# #Actual endpoints
# resource "aws_sagemaker_endpoint" "car_detection_model_endpoint" {
#   name                 = "car-detection-model-endpoint"
#   endpoint_config_name = aws_sagemaker_endpoint_configuration.car-detection-model-endpoint-config.name
# }

# resource "aws_sagemaker_endpoint" "license_plate_detection_model_endpoint" {
#   name                 = "license-plate-detection-model-endpoint"
#   endpoint_config_name = aws_sagemaker_endpoint_configuration.license-plate-detection-model-endpoint-config.name
# }

# resource "aws_sagemaker_endpoint" "license_plate_rectification_model_endpoint" {
#   name                 = "license-plate-rectification-model-endpoint"
#   endpoint_config_name = aws_sagemaker_endpoint_configuration.license-plate-rectification-model-endpoint-config.name
# }
