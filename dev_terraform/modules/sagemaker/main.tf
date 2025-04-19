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

# IAM Role for model monitoring
resource "aws_iam_role" "sagemaker_monitor_role" {
  name = "sagemaker-monitoring-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "sagemaker.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# IAM Policy for the monitoring role
resource "aws_iam_role_policy" "monitor_policy" {
  name = "sagemaker-monitoring-policy"
  role = aws_iam_role.sagemaker_monitor_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "cloudwatch:PutMetricData"
        ],
        Resource = "*"
      }
    ]
  })
}

data "aws_ecr_repository" "car_detect" {
  name = "car-detect"
}

# Create model for car detection
resource "aws_sagemaker_model" "car_detect_model" {
  name               = "car-detect-model"
  execution_role_arn = aws_iam_role.sagemaker_execution_role.arn

  primary_container {
    image = "${data.aws_ecr_repository.car_detect.repository_url}@sha256:93521dc241c7f4a58ddabca6eefc57f60df2c84951b56f6b12fe1c32e8cd9b58"
    # If your model is contained in the Docker image, you don't need model_data_url
  }

  tags = {
    ModelPackageGroupName = aws_sagemaker_model_package_group.spot-model-registry.model_package_group_name
    environment           = "dev"
    repository            = "car-detect"
  }
}

resource "aws_sagemaker_endpoint_configuration" "car_detect_endpoint_config" {
  name = "car-detect-endpoint-config"

  production_variants {
    variant_name           = "car-detect-variant"
    model_name             = aws_sagemaker_model.car_detect_model.name
    initial_instance_count = 1
    instance_type          = "ml.m5.large"
  }

  tags = {
    environment = "dev"
  }
}

resource "aws_sagemaker_endpoint" "car_detect_endpoint" {
  name                 = "car-detect-endpoint"
  endpoint_config_name = aws_sagemaker_endpoint_configuration.car_detect_endpoint_config.name

  tags = {
    environment = "dev"
  }
}

resource "aws_sagemaker_monitoring_schedule" "car_detect_data_quality_monitoring" {
  name = "car-detect-monitoring-schedule"

  monitoring_schedule_config {
    schedule_config {
      schedule_expression = "cron(0 * ? * * *)" # Run every hour
    }

    monitoring_job_definition {
      baseline_config {
        constraints_resource {
          s3_uri = "s3://${aws_s3_bucket.model_artifacts.bucket}/baselines/car_detect/constraints.json"
        }
        statistics_resource {
          s3_uri = "s3://${aws_s3_bucket.model_artifacts.bucket}/baselines/car_detect/statistics.json"
        }
      }

      monitoring_inputs {
        endpoint_input {
          endpoint_name              = aws_sagemaker_endpoint.car_detect_endpoint.name
          local_path                 = "/opt/ml/processing/input"
          s3_input_mode              = "File"
          s3_data_distribution_type = "FullyReplicated"
        }
      }

      monitoring_output_config {
        monitoring_outputs {
          s3_output {
            s3_uri = "s3://${aws_s3_bucket.model_artifacts.bucket}/monitoring-output/car_detect/"
          }
        }
      }

      monitoring_resources {
        cluster_config {
          instance_count     = 1
          instance_type      = "ml.m5.large"
          volume_size_in_gb = 20
        }
      }

      role_arn = aws_iam_role.sagemaker_monitor_role.arn

      stopping_condition {
        max_runtime_in_seconds = 1800
      }
    }
  }
}

data "aws_ecr_repository" "lpr_detect" {
  name = "lpr-detect"
}


resource "aws_sagemaker_model" "lpr_detect_model" {
  name               = "lpr-detect-model"
  execution_role_arn = aws_iam_role.sagemaker_execution_role.arn

  primary_container {
    image = "${data.aws_ecr_repository.lpr_detect.repository_url}@sha256:3968811d6c38e4e251bc4cd54f3b3a26eb0c2b2730db5434b2c85ab9ab54ef17"
    # If your model is contained in the Docker image, you don't need model_data_url
  }

  tags = {
    ModelPackageGroupName = aws_sagemaker_model_package_group.spot-model-registry.model_package_group_name
    environment           = "dev"
    repository            = "lpr-detect"
  }
}

resource "aws_sagemaker_endpoint_configuration" "lpr_detect_endpoint_config" {
  name = "lpr-detect-endpoint-config"

  production_variants {
    variant_name           = "lpr-detect-variant"
    model_name             = aws_sagemaker_model.lpr_detect_model.name
    initial_instance_count = 1
    instance_type          = "ml.m5.large"
  }

  tags = {
    environment = "dev"
  }
}

resource "aws_sagemaker_endpoint" "lpr_detect_endpoint" {
  name                 = "lpr-detect-endpoint"
  endpoint_config_name = aws_sagemaker_endpoint_configuration.lpr_detect_endpoint_config.name

  tags = {
    environment = "dev"
  }
}

# Generate a random suffix for unique naming
resource "random_id" "suffix" {
  byte_length = 4
}

# Create S3 bucket for feature store
resource "aws_s3_bucket" "feature_store" {
  bucket = "spot-model-artifacts-${random_id.suffix.hex}"
}

# IAM Role for SageMaker Feature Group
resource "aws_iam_role" "sagemaker_feature_store" {
  name = "sagemaker-feature-store-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "sagemaker.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# IAM Policy for accessing S3 and other resources
resource "aws_iam_policy" "feature_store_policy" {
  name        = "car-detections-feature-store-policy"
  description = "Access to image data and metadata"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetObject",
          "s3:ListBucket",
          "s3:PutObject"
        ]
        Effect = "Allow"
        Resource = [
          aws_s3_bucket.feature_store.arn,
          "${aws_s3_bucket.feature_store.arn}/*"
        ]
      },
      {
        Action = [
          "sagemaker:*",
          "glue:*"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

# Attach the policy to the IAM role
resource "aws_iam_role_policy_attachment" "feature_store_attach" {
  role       = aws_iam_role.sagemaker_feature_store.name
  policy_arn = aws_iam_policy.feature_store_policy.arn
}

# SageMaker Feature Group
resource "aws_sagemaker_feature_group" "image_metadata" {
  feature_group_name             = "car-detections-feature-group"
  record_identifier_feature_name = "image_id"
  event_time_feature_name        = "processing_time"
  role_arn                       = aws_iam_role.sagemaker_feature_store.arn
  description                    = "Stores image metadata and bounding boxes"

  feature_definition {
    feature_name = "image_id"
    feature_type = "String"
  }
  feature_definition {
    feature_name = "processing_time"
    feature_type = "String" # ISO 8601 timestamp
  }
  feature_definition {
    feature_name = "s3_image_uri"
    feature_type = "String"
  }
  feature_definition {
    feature_name = "bounding_boxes"
    feature_type = "String"
  }

  offline_store_config {
    s3_storage_config {
      s3_uri = "s3://${aws_s3_bucket.feature_store.bucket}/image-metadata/"
    }
    disable_glue_table_creation = false
  }

  online_store_config {
    enable_online_store = false
  }

  # Ensure bucket exists first
  depends_on = [aws_s3_bucket.feature_store]
}


#resource "aws_sagemaker_notebook_instance" "inferencing_notebook" {
#    name = "inferencing-notebook"
#    instance_type = "ml.t2.medium"
#    role_arn = var.role_arn
#}
