resource "aws_sagemaker_notebook_instance" "inferencing_notebook" {
    name = "inferencing-notebook"
    instance_type = "ml.t2.medium"
    role_arn = var.role_arn
}

# Models for AWS Sagemaker
resource "aws_sagemaker_model" "car-detection-model" {
  name                  = "car-detection-model"
  execution_role_arn    = var.role_arn
  primary_container {
    image               = "123456789012.dkr.ecr.us-west-1.amazonaws.com/spotpark-model:latest" # Replace with your actual image URI
    model_data_url      = "s3://spotpark-model-artifacts/model.tar.gz" # Replace with your actual model artifact path
  }
}

resource "aws_sagemaker_model" "license-plate-detection-model" {
  name                  = "license-plate-detection-model"
  execution_role_arn    = var.role_arn
  primary_container {
    image               = "123456789012.dkr.ecr.us-west-1.amazonaws.com/spotpark-model:latest" # Replace with your actual image URI
    model_data_url      = "s3://spotpark-model-artifacts/model.tar.gz" # Replace with your actual model artifact path
  }
}

resource "aws_sagemaker_model" "license-plate-rectification-model" {
  name                  = "license-plate-rectification-model"
  execution_role_arn    = var.role_arn
  primary_container {
    image               = "123456789012.dkr.ecr.us-west-1.amazonaws.com/spotpark-model:latest" # Replace with your actual image URI
    model_data_url      = "s3://spotpark-model-artifacts/model.tar.gz" # Replace with your actual model artifact path
  }
}


#Endpoint configurations
resource "aws_sagemaker_endpoint_configuration" "car_detection_model_endpoint_config" {
  name = "car-detection-model-endpoint-config"
  production_variants {
    variant_name           = "car-detection-variant"
    model_name             = aws_sagemaker_model.car-detection-model.name
    initial_instance_count = 1
    instance_type          = "ml.t2.medium"
  }
}

resource "aws_sagemaker_endpoint_configuration" "license_plate_detection_model_endpoint_config" {
  name = "license-plate-detection-model-endpoint-config"
  production_variants {
    variant_name           = "license-plate-detection-variant"
    model_name             = aws_sagemaker_model.license-plate-detection-model.name
    initial_instance_count = 1
    instance_type          = "ml.t2.medium"
  }
}

resource "aws_sagemaker_endpoint_configuration" "license_plate_rectification_model_endpoint_config" {
  name = "license-plate-rectification-model-endpoint-config"
  production_variants {
    variant_name           = "license-plate-rectification-variant"
    model_name             = aws_sagemaker_model.license-plate-rectification-model.name
    initial_instance_count = 1
    instance_type          = "ml.t2.medium"
  }
}


#Actual endpoints
resource "aws_sagemaker_endpoint" "car_detection_model_endpoint" {
  name                 = "car-detection-model-endpoint"
  endpoint_config_name = aws_sagemaker_endpoint_configuration.car-detection-model-endpoint-config.name
}

resource "aws_sagemaker_endpoint" "license_plate_detection_model_endpoint" {
  name                 = "license-plate-detection-model-endpoint"
  endpoint_config_name = aws_sagemaker_endpoint_configuration.license-plate-detection-model-endpoint-config.name
}

resource "aws_sagemaker_endpoint" "license_plate_rectification_model_endpoint" {
  name                 = "license-plate-rectification-model-endpoint"
  endpoint_config_name = aws_sagemaker_endpoint_configuration.license-plate-rectification-model-endpoint-config.name
}