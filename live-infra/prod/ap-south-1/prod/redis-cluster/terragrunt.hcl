include {
  path = find_in_parent_folders()
}

locals {
  # Automatically load environment-level variables
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))

  region_vars = read_terragrunt_config(find_in_parent_folders("region.hcl"))

}

include "envcommon" {
  path = "${dirname(find_in_parent_folders())}/_envcommon/commonlib.hcl"
}


terraform {
  source = "git@github.com:cloudposse/terraform-aws-elasticache-redis.git?ref=tags/0.53.0"
}


dependency "default_network" {
  config_path = "../network"
}


inputs = {
  region                     = local.region_vars.locals.aws_region
  availability_zones         = ["ap-south-1a", "ap-south-1b"]
  namespace                  = local.environment_vars.locals.namespace
  stage                      = local.environment_vars.locals.stage
  vpc_id                     = dependency.default_network.outputs.default_vpc
  name                       = "redis-ssd-cluster"
  allowed_security_group_ids = [
    dependency.default_network.outputs.aws_default_security_group
  ]
  subnets = [
    dependency.default_network.outputs.default_subnet, dependency.default_network.outputs.default_subnetb
  ]
  cluster_size                  = 2
  instance_type                 = "cache.r6gd.xlarge"
  apply_immediately             = true
  automatic_failover_enabled    = true
  engine_version                = "7.0"
  family                        = "redis7"
  at_rest_encryption_enabled    = true
  transit_encryption_enabled    = false
  create_security_group         = false
  data_tiering_enabled          = true
  associated_security_group_ids = [dependency.default_network.outputs.aws_default_security_group, "sg-088a8d9c23a35afdf"]
}