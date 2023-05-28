include {
  path = find_in_parent_folders()
}

locals {
  # Automatically load environment-level variables

  common_vars = read_terragrunt_config("${dirname(find_in_parent_folders())}/_envcommon/commonlib.hcl")


}

terraform {
  source = "${local.common_vars.locals.base_cloudposse_source_url}/terraform-aws-ecr.git?ref=tags/0.38.0"
}


inputs = {
  namespace              = "ondc"
  stage                  = "prod"
  name                   = "ondc-images"
  principals_full_access = ["arn:aws:iam::${local.common_vars.locals.aws_account_id}:root"]
}
