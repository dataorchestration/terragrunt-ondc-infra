module "s3_log_storage" {
  source                 = "cloudposse/s3-log-storage/aws"
  version                = "0.28.0"
  namespace              = var.namespace
  stage                  = var.stage
  name                   = var.name
  attributes             = ["logs"]
  force_destroy          = true
  lifecycle_rule_enabled = false
  force_destroy_enabled  = true
}

module "aws_key_pair" {
  source              = "cloudposse/key-pair/aws"
  version             = "0.18.3"
  namespace           = var.namespace
  stage               = var.stage
  name                = var.name
  attributes          = ["ssh", "key"]
  ssh_public_key_path = var.ssh_public_key_path
  generate_ssh_key    = var.generate_ssh_key
}


module "emr_cluster" {
  source                                         = "cloudposse/emr-cluster/aws"
  version                                        = "0.22.3"
  namespace                                      = var.namespace
  stage                                          = var.stage
  name                                           = var.name
  master_allowed_security_groups                 = [var.vpc_default_security_group_id]
  slave_allowed_security_groups                  = [var.vpc_default_security_group_id]
  region                                         = var.aws_region
  vpc_id                                         = var.vpc_id
  subnet_id                                      = var.subnet_id
  route_table_id                                 = var.private_route_table_id
  subnet_type                                    = "public"
  ebs_root_volume_size                           = var.ebs_root_volume_size
  visible_to_all_users                           = var.visible_to_all_users
  release_label                                  = var.release_label
  applications                                   = var.applications
  configurations_json                            = "${data.template_file.cluster_configuration.rendered}"
  core_instance_group_instance_type              = var.core_instance_group_instance_type
  core_instance_group_instance_count             = var.core_instance_group_instance_count
  core_instance_group_ebs_size                   = var.core_instance_group_ebs_size
  core_instance_group_ebs_type                   = var.core_instance_group_ebs_type
  core_instance_group_ebs_volumes_per_instance   = var.core_instance_group_ebs_volumes_per_instance
  master_instance_group_instance_type            = var.master_instance_group_instance_type
  master_instance_group_instance_count           = var.master_instance_group_instance_count
  master_instance_group_ebs_size                 = var.master_instance_group_ebs_size
  master_instance_group_ebs_type                 = var.master_instance_group_ebs_type
  master_instance_group_ebs_volumes_per_instance = var.master_instance_group_ebs_volumes_per_instance
  create_task_instance_group                     = var.create_task_instance_group
  log_uri                                        = format("s3n://%s/", module.s3_log_storage.bucket_id)
  key_name                                       = module.aws_key_pair.key_name
  task_instance_group_autoscaling_policy         = "${data.template_file.cluster_auto_scaling_configuration.rendered}"
  task_instance_group_instance_count             = var.task_instance_group_instance_count
  task_instance_group_ebs_size                   = var.task_instance_group_ebs_size
  task_instance_group_ebs_type                   = var.task_instance_group_ebs_type
  task_instance_group_ebs_volumes_per_instance   = var.master_instance_group_ebs_volumes_per_instance
  task_instance_group_instance_type              = var.task_instance_group_instance_type
  task_instance_group_bid_price = var.task_instance_group_bid_price
  core_instance_group_bid_price = var.core_instance_group_bid_price
  keep_job_flow_alive_when_no_steps = var.keep_job_flow_alive_when_no_steps
}


module "bridge_instance" {
  count                       = var.enable_bridge_instance ? 1 : 0
  source                      = "git::https://github.com/cloudposse/terraform-aws-ec2-instance.git?ref=tags/0.42.0"
  ssh_key_pair                = module.aws_key_pair.key_name
  vpc_id                      = var.vpc_id
  subnet                      = var.public_subnet_id
  associate_public_ip_address = true
  name                        = "ec2_bridge"
  namespace                   = var.namespace
  stage                       = var.stage
  additional_ips_count        = 0
  ebs_volume_count            = 1
  instance_type               = "t2.nano"
  region                      = "${var.aws_region}"
  security_groups             = [var.vpc_default_security_group_id]
  security_group_rules        = [
    {
      "cidr_blocks" : [
        "0.0.0.0/0"
      ],
      "description" : "Allow all outbound traffic",
      "from_port" : 0,
      "protocol" : "-1",
      "to_port" : 65535,
      "type" : "egress"
    },
    {
      "cidr_blocks" : [
        "0.0.0.0/0"
      ],
      "description" : "Allow all ssh traffic on 22",
      "from_port" : 22,
      "protocol" : "-1",
      "to_port" : 22,
      "type" : "ingress"
    }
  ]
}