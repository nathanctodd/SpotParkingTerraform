resource "aws_emr_cluster" "inferencing_cluster" {
  name            = "inferencing_cluster"
  release_label   = "emr-6.2.0"
  applications    = ["Spark"]

  service_role = var.emr_service_role_arn

  ec2_attributes {
    instance_profile = var.emr_instance_profile_arn
  }

  # Master node (required)
  master_instance_fleet {
    instance_type_configs {
      instance_type = "m5.xlarge"
    }
    target_on_demand_capacity = 1
  }

  # Core nodes (optional but usually required)
  core_instance_fleet {
    instance_type_configs {
      instance_type = "m5.xlarge"
    }
    target_on_demand_capacity = 2
  }


  configurations_json = <<EOF
[
  {
    "Classification": "spark",
    "Properties": {
      "maximizeResourceAllocation": "true"
    }
  }
]
EOF
}