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
  source = "../../../../../modules//eks"
}


dependency "default_network" {
  config_path = "../network"
}


inputs = {
  region                     = local.region_vars.locals.aws_region
  namespace                  = local.environment_vars.locals.namespace
  stage                      = local.environment_vars.locals.stage
  vpc_id                     = dependency.default_network.outputs.default_vpc
  subnet_ids                 = [
    dependency.default_network.outputs.default_subnet, dependency.default_network.outputs.default_subnetb
  ]
  allowed_security_group_ids = [
    dependency.default_network.outputs.aws_default_security_group
  ]
  region                    = "ap-south-1"
  allowed_cidr_blocks       = [dependency.default_network.outputs.default_vpc_cidr_block]
  availability_zones        = ["ap-south-1a", "ap-south-1b"]
  vpc_cidr_block            = dependency.default_network.outputs.default_vpc_cidr_block
  default_security_group_id = dependency.default_network.outputs.aws_default_security_group
  namespace                 = "ondc"

  stage = "prod"

  name = "eks"

  # oidc_provider_enabled is required to be true for VPC CNI addon
  oidc_provider_enabled = true

  enabled_cluster_log_types = ["audit"]

  cluster_log_retention_period = 7

  instance_types = ["t3.medium"]

  desired_size = 2

  max_size = 3

  min_size = 2

  kubernetes_labels = {}

  cluster_encryption_config_enabled = true

  # When updating the Kubernetes version, also update the API and client-go version in test/src/go.mod
  kubernetes_version = "1.26"

  addons = [
    // https://docs.aws.amazon.com/eks/latest/userguide/managing-vpc-cni.html#vpc-cni-latest-available-version
    {
      addon_name               = "vpc-cni"
      addon_version            = null
      resolve_conflicts        = "NONE"
      service_account_role_arn = null
    },
    // https://docs.aws.amazon.com/eks/latest/userguide/managing-kube-proxy.html
    {
      addon_name               = "kube-proxy"
      addon_version            = null
      resolve_conflicts        = "NONE"
      service_account_role_arn = null
    },
    // https://docs.aws.amazon.com/eks/latest/userguide/managing-coredns.html
    {
      addon_name               = "coredns"
      addon_version            = null
      resolve_conflicts        = "NONE"
      service_account_role_arn = null
    },
  ]

}
