resource "aws_emr_cluster" "inferencing_cluster" {
  name            = "inferencing_cluster"
  release_label   = "emr-6.2.0"
  applications    = ["Spark"]
  service_role    = var.emr_service_role_arn

  configurations_json = <<EOF
    {
        "Classification": "spark",
        "Properties": {
            "maximizeResourceAllocation": "true"
        }
    }
    EOF
}
