#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Define variables
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)
MODEL_REGISTRY_NAME="spotparking-model-registry"
MODEL_BUNDLE_DIR="./models"
TERRAFORM_DIR="./model_terraform"

echo "Checking AWS CLI authentication..."
if ! aws sts get-caller-identity > /dev/null 2>&1; then
    echo "Error: AWS CLI is not authenticated. Please run 'aws configure' to set up your credentials."
    exit 1
fi


# Step 1: Initialize and apply Terraform to create the model registry

echo "Checking if model registry exists..."
if aws s3api head-bucket --bucket "$MODEL_REGISTRY_NAME" 2>/dev/null; then
    echo "Model registry $MODEL_REGISTRY_NAME already exists. Skipping creation."
else
    echo "Model registry $MODEL_REGISTRY_NAME does not exist. Proceeding with creation."
    echo "Initializing and applying Terraform to create the model registry..."
    cd "$TERRAFORM_DIR"
    terraform init
    terraform apply -auto-approve -var="model_registry_name=$MODEL_REGISTRY_NAME"
fi

# Step 2: Bundle models
echo "Bundling models..."
if [ ! -d "$MODEL_BUNDLE_DIR" ]; then
    echo "Model directory $MODEL_BUNDLE_DIR does not exist. Please add your models to this directory."
    exit 1
fi

BUNDLE_FILE="model_bundle.tar.gz"
tar -czf "$BUNDLE_FILE" -C "$MODEL_BUNDLE_DIR" .

# Step 3: Push bundled models to the registry
echo "Pushing bundled models to the registry..."
# Replace this with the actual command to push to your model registry
aws s3 cp "$BUNDLE_FILE" s3://$MODEL_REGISTRY_NAME/
echo "Model uploaded to s3://$MODEL_REGISTRY_NAME/"
echo "Model bundle $BUNDLE_FILE pushed successfully."

# Cleanup
rm "$BUNDLE_FILE"
echo "Model registry setup and model push completed successfully."