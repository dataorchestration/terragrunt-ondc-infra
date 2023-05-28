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
  source = "../../../../../modules//default_networking"
}

inputs = {
  availablity_zone  = "ap-south-1a"
  availablity_zoneb = "ap-south-1b"
  availablity_zonec = "ap-south-1c"
  tags              = {
    "kubernetes.io/role/elb" : "1"
    "kubernetes.io/cluster/ondc-prod-prod-eks-cluster" : "owned"
  }

}