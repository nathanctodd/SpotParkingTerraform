import boto3
import json

# This script creates a monitoring schedule for a SageMaker endpoint using the boto3 library.
# It assumes that the necessary IAM role and S3 bucket already exist.
# If not, it will create them.
# Make sure to install boto3 if you haven't already

# Initialize boto3 clients
sagemaker_client = boto3.client('sagemaker')

ENDPOINT_NAME = "car-detect-endpoint"
MONITORING_SCHDEULE_NAME = "car-detect-monitoring-schedule"
REFERENCE_DATASET_BUCKET = "car-detect-reference-dataset" # TODO: change this to your bucket name that has reference dataset
iam_client = boto3.client('iam')
role_name = "SageMakerExecutionRole"

try:
    role = iam_client.create_role(
        RoleName=role_name,
        AssumeRolePolicyDocument=json.dumps({
            "Version": "2012-10-17",
            "Statement": [
                {
                    "Effect": "Allow",
                    "Principal": {
                        "Service": "sagemaker.amazonaws.com"
                    },
                    "Action": "sts:AssumeRole"
                }
            ]
        })
    )
    print(f"Role '{role_name}' created successfully.")
    # Attach necessary policies to the role
    iam_client.attach_role_policy(
        RoleName=role_name,
        PolicyArn="arn:aws:iam::aws:policy/AmazonSageMakerFullAccess"
    )
    iam_client.attach_role_policy(
        RoleName=role_name,
        PolicyArn="arn:aws:iam::aws:policy/AmazonS3FullAccess"
    )
    iam_client.attach_role_policy(
        RoleName=role_name,
        PolicyArn="arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
    )
    print(f"Policies attached to role '{role_name}'.")
except iam_client.exceptions.EntityAlreadyExistsException:
    print(f"Role '{role_name}' already exists.")
    role = iam_client.get_role(RoleName=role_name)

role_arn = role['Role']['Arn']
MONITORING_OUTPUT_BUCKET = "sagemaker-monitoring-output"

# Create the S3 bucket if it doesn't exist
s3_client = boto3.client('s3')
try:
    s3_client.create_bucket(
        Bucket=MONITORING_OUTPUT_BUCKET,
        CreateBucketConfiguration={
            'LocationConstraint': boto3.session.Session().region_name
        }
    )
    print(f"Bucket '{MONITORING_OUTPUT_BUCKET}' created successfully.")
except s3_client.exceptions.BucketAlreadyOwnedByYou:
    print(f"Bucket '{MONITORING_OUTPUT_BUCKET}' already exists.")

# Create a baseline job
baseline_job_name = "car-detect-baseline-job"
baseline_response = sagemaker_client.create_processing_job(
    ProcessingJobName=baseline_job_name,
    AppSpecification={
        'ImageUri': '156387875391.dkr.ecr.us-west-1.amazonaws.com/sagemaker-model-monitor-analyzer',
        'ContainerEntrypoint': ['python3'],
        'ContainerArguments': ['--baseline']
    },
    RoleArn=role_arn,
    ProcessingInputs=[
        {
            'InputName': 'baseline-data',
            'S3Input': {
                'S3Uri': f's3://{REFERENCE_DATASET_BUCKET}/data.csv',
                'LocalPath': '/opt/ml/processing/input',
                'S3DataType': 'S3Prefix',
                'S3InputMode': 'File'
            }
        }
    ],
    ProcessingOutputConfig={
        'Outputs': [
            {
                'OutputName': 'baseline-output',
                'S3Output': {
                    'S3Uri': f's3://{MONITORING_OUTPUT_BUCKET}/{baseline_job_name}/output',
                    'LocalPath': '/opt/ml/processing/output',
                    'S3UploadMode': 'EndOfJob'
                }
            }
        ]
    }
)

print(f"Baseline job created: {baseline_response['ProcessingJobArn']}")

# Create a monitoring schedule
monitoring_response = sagemaker_client.create_monitoring_schedule(
    MonitoringScheduleName=MONITORING_SCHDEULE_NAME,
    MonitoringScheduleConfig={
        'MonitoringJobDefinition': {
            'BaselineConfig': {
                'ConstraintsResource': {
                    'S3Uri': f's3://{REFERENCE_DATASET_BUCKET}/{baseline_job_name}/output/constraints.json'
                }
            },
            'MonitoringInputs': [
                {
                    'EndpointInput': {
                        'EndpointName': ENDPOINT_NAME,
                        'LocalPath': '/opt/ml/processing/input'
                    }
                }
            ],
            'MonitoringOutputConfig': {
                'MonitoringOutputs': [
                    {
                        'S3Output': {
                            'S3Uri': f's3://{REFERENCE_DATASET_BUCKET}/{MONITORING_SCHDEULE_NAME}/output',
                            'LocalPath': '/opt/ml/processing/output',
                            'S3UploadMode': 'EndOfJob'
                        }
                    }
                ]
            },
            'MonitoringResources': {
                'ClusterConfig': {
                    'InstanceCount': 1,
                    'InstanceType': 'ml.m5.large', # this is the instance type for the monitoring job --> current type is not super cheap nor super expensive
                    'VolumeSizeInGB': 30
                }
            },
            'RoleArn': role_arn,
            'StoppingCondition': {
                'MaxRuntimeInSeconds': 3600
            }
        }
    }
)

print(f"Monitoring schedule created: {monitoring_response['MonitoringScheduleArn']}")
