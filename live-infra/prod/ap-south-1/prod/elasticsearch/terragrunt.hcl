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
  source = "git@github.com:cloudposse/terraform-aws-elasticsearch.git?ref=tags/0.46.0"
}


dependency "default_network" {
  config_path = "../network"
}


inputs = {
  region     = local.region_vars.locals.aws_region
  namespace  = local.environment_vars.locals.namespace
  stage      = local.environment_vars.locals.stage
  vpc_id     = dependency.default_network.outputs.default_vpc
  subnet_ids = [
    dependency.default_network.outputs.default_subnet, dependency.default_network.outputs.default_subnetb
  ]
  allowed_security_group_ids = [
    dependency.default_network.outputs.aws_default_security_group
  ]
  region              = "ap-south-1"
  allowed_cidr_blocks = [dependency.default_network.outputs.default_vpc_cidr_block]
  availability_zones  = ["ap-south-1a", "ap-south-1b"]
  vpc_cidr_block      = dependency.default_network.outputs.default_vpc_cidr_block
  security_groups     = [dependency.default_network.outputs.aws_default_security_group, "sg-088a8d9c23a35afdf"]
  namespace           = "ondc"

  stage = "prod"

  name = "es"

  instance_types = ["t3.medium"]

  zone_awareness_enabled         = true
  elasticsearch_version          = "7.7"
  instance_type                  = "t3.medium.elasticsearch"
  instance_count                 = 2
  encrypt_at_rest_enabled        = false
  dedicated_master_enabled       = true
  create_iam_service_linked_role = true
  kibana_subdomain_name          = "kibana"
  ebs_volume_size                = 200
  dns_zone_id                    = "Z08533003KY88F2IM0N8X"
  kibana_hostname_enabled        = true
  domain_hostname_enabled        = true
  advanced_options               = {
    "rest.action.multi.allow_explicit_index" = "true"
  }
  dedicated_master_type = "t3.small.elasticsearch"
  tags = {
    "Environment" = "prod"
    "Name"        = "es"
    "Namespace"   = "ondc"
    "component"   = "es"
  }


}
