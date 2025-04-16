provider "aws" {
    region = "us-west-1"
}

resource "aws_s3_bucket" "model_registry" {
    bucket = "spot-parking-model-registry"
    acl    = "private"

    versioning {
        enabled = true
    }

    tags = {
        Name        = "ModelRegistry"
        Environment = "Production"
    }
}

resource "aws_dynamodb_table" "model_registry_metadata" {
    name           = "ModelRegistryMetadata"
    billing_mode   = "PAY_PER_REQUEST"
    hash_key       = "ModelName"
    range_key      = "Version"

    attribute {
        name = "ModelName"
        type = "S"
    }

    attribute {
        name = "Version"
        type = "S"
    }

    tags = {
        Name        = "ModelRegistryMetadata"
        Environment = "Production"
    }
}