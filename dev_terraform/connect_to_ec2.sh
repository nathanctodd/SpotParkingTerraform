#!/bin/zsh

# Check if the parameter is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <key_name>"
    exit 1
fi

# Set the key name from the parameter
KEY_NAME=$1

# Set the permissions for the private key file
chmod 400 ${KEY_NAME}.pem

# Get the public IP address of the EC2 instance from Terraform output
INSTANCE_PUBLIC_IP=$(terraform output -raw ${KEY_NAME}_instance_public_ip)

# Connect to the EC2 instance via SSH
ssh -i ${KEY_NAME}.pem ec2-user@$INSTANCE_PUBLIC_IP