You will need to create a .tfvars file in each terraform directory and add the following to each respectively:

`dev_terraform/terraform.tfvars`
```
aws_profile = "dev-profile-name-here"
```

`prod_terraform/terraform.tfvars`
```
aws_profile = "prod-profile-name-here"
```

`test_terraform/terraform.tfvars`
```
aws_profile = "test-profile-name-here"
```


## Quick defintion of outputs and variables in terraform

### Variables

- Purpose: Variables are used to pass data into a module or configuration.
 
- Direction: Variables are "inputs" to a module.

- Defined In: variables.tf file (or directly in main.tf if you prefer not to use variables.tf).

### Outputs

- Purpose: Outputs are used to expose data from a module to the parent module (or root configuration).

- Direction: Outputs are "outputs" from a module.

- Defined In: outputs.tf file (or directly in main.tf if you prefer not to use outputs.tf).


__In your root configuration (main.tf), you connect them__


## Useful Terraform/AWS cli commands

Reauthenticate device to AWS account (profile)
```
aws sso login --profile spot-dev
```

Check what AWS profile your device is set to
```
aws configure list | grep profile
```

Set your AWS profile on your device (assuming you have created a profile named spot-dev)
```
export AWS_PROFILE=spot-dev
```

For this error even after re-authenticating:
```
Error: validating provider credentials: retrieving caller identity from STS: operation error STS: GetCallerIdentity, https response error StatusCode: 403, RequestID: 7d279d3f-e390-4cb7-9b06-8a12a5cefe53, api error ExpiredToken: The security token included in the request is expired
```
...
Reset your AWS credentials:
```
mv ~/.aws/credentials ~/.aws/credentials.backup

```


# Connecting to an EC2 instance in AWS

```
./connect_to_ec2.sh {name_of_ec2}
```
EC2 Options
- star-command
- voyager-tracking
- kirk-event-manager

Or you can use EC2 connect in the AWS console under the EC2 section


## Pull Latest Image & Restart Container

### Authenticate with ECR
Make sure you're authenticated with ECR using the AWS CLI:
```bash
aws ecr get-login-password --region us-west-1 | \
docker login --username AWS --password-stdin 442426871585.dkr.ecr.us-west-1.amazonaws.com
```

*Note: The dev AWS account id is `442426871585`*

### Pull the latest image
```bash
docker pull 442426871585.dkr.ecr.us-west-1.amazonaws.com/voyager-tracking:latest
```

### Stop and remove the current container
Find the container:
```bash
docker ps # or docker ps -a
```

Then stop and remove it:
```bash
docker stop voyager-tracking
docker rm voyager-tracking
```
*Note: Replace `voyager-tracking` with your actual container name if it's different.*

### Run the container again
Assuming you want to run it detached and possibly map ports:
```bash
docker run -d --name voyager-tracking \
-p 80:8000 \
{image-uri}:latest
```

A working formatted version:
```bash
docker run -d --name voyager-tracking \
-p 80:8000 \
442426871585.dkr.ecr.us-west-1.amazonaws.com/voyager-tracking:latest
```


*Adjust volumes, environment variables, or other flags as needed*


