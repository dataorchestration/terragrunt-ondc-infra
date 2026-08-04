include {
  path = find_in_parent_folders()
}

locals {
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  region_vars      = read_terragrunt_config(find_in_parent_folders("region.hcl"))
  variables        = read_terragrunt_config("${get_terragrunt_dir()}/variables.hcl")
}

include "envcommon" {
  path = "${dirname(find_in_parent_folders())}/_envcommon/commonlib.hcl"
}

terraform {
  source = "git@github.com:cloudposse/terraform-aws-redshift-cluster.git?ref=tags/v1.3.1"
}

# Pin AWS provider to 5.x — the cloudposse module v1.3.1 still uses the
# inline `logging` block on aws_redshift_cluster, which was removed in
# AWS provider v6.0. See cloudposse/terraform-aws-redshift-cluster#39.
generate "provider_versions" {
  path      = "provider_versions_override.tf"
  if_exists = "overwrite"
  contents  = <<EOF
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0, < 6.0"
    }
  }
}
EOF
}

dependency "default_network" {
  config_path = "../network"
}

dependency "s3_read_role" {
  config_path = "../redshift-s3-read-role"

  mock_outputs = {
    arn = "arn:aws:iam::000000000000:role/mock-redshift-s3-read"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

inputs = {
  region    = local.region_vars.locals.aws_region
  namespace = local.environment_vars.locals.namespace
  stage     = local.environment_vars.locals.stage
  name      = local.variables.locals.name

  node_type       = local.variables.locals.node_type
  cluster_type    = local.variables.locals.cluster_type
  number_of_nodes = local.variables.locals.number_of_nodes

  database_name  = local.variables.locals.database_name
  admin_user     = local.variables.locals.admin_user
  admin_password = get_env("REDSHIFT_ADMIN_PASSWORD")

  subnet_ids             = [dependency.default_network.outputs.default_subnet, dependency.default_network.outputs.default_subnetb]
  vpc_security_group_ids = [dependency.default_network.outputs.aws_default_security_group]

  iam_roles = [dependency.s3_read_role.outputs.arn]

  publicly_accessible = local.variables.locals.publicly_accessible
  encrypted           = local.variables.locals.encrypted

  automated_snapshot_retention_period = local.variables.locals.automated_snapshot_retention_period
  skip_final_snapshot                 = local.variables.locals.skip_final_snapshot
  final_snapshot_identifier           = local.variables.locals.final_snapshot_identifier
}