include {
  path = find_in_parent_folders()
}

locals {
  # Automatically load environment-level variables
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))

  region_vars = read_terragrunt_config(find_in_parent_folders("region.hcl"))

  common_vars = read_terragrunt_config("${dirname(find_in_parent_folders())}/_envcommon/commonlib.hcl")

  common_scripts_path = "${dirname(find_in_parent_folders())}/scripts"

}

include "envcommon" {
  path = "${dirname(find_in_parent_folders())}/_envcommon/commonlib.hcl"
}

terraform {
  source = "${local.common_vars.locals.base_cloudposse_source_url}/terraform-aws-ec2-instance.git?ref=tags/0.42.0"
}

generate "kyndryl_sync_iam" {
  path      = "kyndryl-sync-iam.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<-EOF
    resource "aws_iam_role_policy_attachment" "kyndryl_sync_ssm" {
      role       = "ondc-gcs-audit-pull"
      policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
    }

    resource "aws_iam_role_policy" "kyndryl_sync_s3" {
      name = "KyndrylGatewaySyncS3"
      role = "ondc-gcs-audit-pull"

      policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
          {
            Sid      = "ReadBucketLocation"
            Effect   = "Allow"
            Action   = "s3:GetBucketLocation"
            Resource = "arn:aws:s3:::ondc-rds-analytics-data-export"
          },
          {
            Sid      = "ListOnlyKyndrylSyncPrefix"
            Effect   = "Allow"
            Action   = "s3:ListBucket"
            Resource = "arn:aws:s3:::ondc-rds-analytics-data-export"
            Condition = {
              StringLike = {
                "s3:prefix" = [
                  "gateway/kyndryl",
                  "gateway/kyndryl/*"
                ]
              }
            }
          },
          {
            Sid    = "ReadWriteWithoutDelete"
            Effect = "Allow"
            Action = [
              "s3:GetObject",
              "s3:PutObject",
              "s3:AbortMultipartUpload",
              "s3:ListMultipartUploadParts"
            ]
            Resource = "arn:aws:s3:::ondc-rds-analytics-data-export/gateway/kyndryl/*"
          }
        ]
      })
    }
  EOF
}

dependency "network" {
  config_path = "../network"
}

dependency "key-pair" {
  config_path = "../bridge_instance_key_pair"
}

inputs = {
  namespace                            = local.environment_vars.locals.namespace
  stage                                = local.environment_vars.locals.stage
  name                                 = "${local.environment_vars.locals.name}-kyndryl-gateway-sync"
  vpc_id                               = dependency.network.outputs.default_vpc
  ssh_key_pair                         = dependency.key-pair.outputs.key_name
  subnet                               = dependency.network.outputs.default_subnet
  associate_public_ip_address          = true
  ebs_volume_count                     = 1
  instance_type                        = "t3.large"
  assign_eip_address                   = false
  region                               = local.region_vars.locals.aws_region
  root_volume_size                     = 200
  ami                                  = "ami-0aa761682283b4cc8"
  ami_owner                            = "099720109477"
  instance_profile                     = "ondc-gcs-audit-pull"
  metadata_http_tokens_required        = true
  metadata_http_endpoint_enabled       = true
  metadata_http_put_response_hop_limit = 2
  metadata_tags_enabled                = false
  security_groups                      = []
  security_group_rules = [
    {
      type        = "egress"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "HTTPS to AWS and Google APIs"
    },
    {
      type        = "egress"
      from_port   = 53
      to_port     = 53
      protocol    = "udp"
      cidr_blocks = ["172.31.0.2/32"]
      description = "VPC DNS"
    },
    {
      type        = "egress"
      from_port   = 53
      to_port     = 53
      protocol    = "tcp"
      cidr_blocks = ["172.31.0.2/32"]
      description = "VPC DNS fallback"
    },
    {
      type        = "egress"
      from_port   = 123
      to_port     = 123
      protocol    = "udp"
      cidr_blocks = ["169.254.169.123/32"]
      description = "Amazon Time Sync Service"
    },
  ]
  user_data = file("${local.common_scripts_path}/docker-compose-install.sh")
}
