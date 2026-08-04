include {
  path = find_in_parent_folders()
}

locals {
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  region_vars      = read_terragrunt_config(find_in_parent_folders("region.hcl"))
  variables        = read_terragrunt_config("${get_terragrunt_dir()}/variables.hcl")

  s3_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ListBucket"
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetBucketLocation",
        ]
        Resource = ["arn:aws:s3:::${local.variables.locals.bucket_name}"]
      },
      {
        Sid    = "ReadObjects"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
        ]
        Resource = ["arn:aws:s3:::${local.variables.locals.bucket_name}/*"]
      },
    ]
  })
}

include "envcommon" {
  path = "${dirname(find_in_parent_folders())}/_envcommon/commonlib.hcl"
}

terraform {
  source = "git@github.com:cloudposse/terraform-aws-iam-role.git?ref=tags/v1.0.0"
}

inputs = {
  namespace = local.environment_vars.locals.namespace
  stage     = local.environment_vars.locals.stage
  name      = local.variables.locals.name

  principals = {
    Service = ["redshift.amazonaws.com"]
  }

  policy_documents      = [local.s3_policy]
  policy_document_count = 1
  policy_description    = "Allow Redshift to read from s3://${local.variables.locals.bucket_name}"
  role_description      = "Assumed by Redshift for COPY FROM s3://${local.variables.locals.bucket_name}"
}