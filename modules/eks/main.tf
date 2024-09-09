module "label" {
  source  = "cloudposse/label/null"
  version = "0.25.0"

  attributes = ["cluster"]

  context = module.this.context
}

locals {
  # The usage of the specific kubernetes.io/cluster/* resource tags below are required
  # for EKS and Kubernetes to discover and manage networking resources
  # https://aws.amazon.com/premiumsupport/knowledge-center/eks-vpc-subnet-discovery/
  # https://github.com/kubernetes-sigs/aws-load-balancer-controller/blob/main/docs/deploy/subnet_discovery.md
  tags = { "kubernetes.io/cluster/${module.label.id}" = "shared" }

  # required tags to make ALB ingress work https://docs.aws.amazon.com/eks/latest/userguide/alb-ingress.html
  public_subnets_additional_tags = {
    "kubernetes.io/role/elb" : 1
  }
  private_subnets_additional_tags = {
    "kubernetes.io/role/internal-elb" : 1
  }
}


module "eks_cluster" {
  source  = "cloudposse/eks-cluster/aws"
  version = "2.8.1"

  vpc_id                       = var.vpc_id
  subnet_ids                   = var.subnet_ids
  kubernetes_version           = var.kubernetes_version
  local_exec_interpreter       = var.local_exec_interpreter
  oidc_provider_enabled        = var.oidc_provider_enabled
  enabled_cluster_log_types    = var.enabled_cluster_log_types
  cluster_log_retention_period = var.cluster_log_retention_period

  cluster_encryption_config_enabled                         = var.cluster_encryption_config_enabled
  cluster_encryption_config_kms_key_id                      = var.cluster_encryption_config_kms_key_id
  cluster_encryption_config_kms_key_enable_key_rotation     = var.cluster_encryption_config_kms_key_enable_key_rotation
  cluster_encryption_config_kms_key_deletion_window_in_days = var.cluster_encryption_config_kms_key_deletion_window_in_days
  cluster_encryption_config_kms_key_policy                  = var.cluster_encryption_config_kms_key_policy
  cluster_encryption_config_resources                       = var.cluster_encryption_config_resources

  addons            = var.addons
  addons_depends_on = [module.eks_node_group]

  # We need to create a new Security Group only if the EKS cluster is used with unmanaged worker nodes.
  # EKS creates a managed Security Group for the cluster automatically, places the control plane and managed nodes into the security group,
  # and allows all communications between the control plane and the managed worker nodes
  # (EKS applies it to ENIs that are attached to EKS Control Plane master nodes and to any managed workloads).
  # If only Managed Node Groups are used, we don't need to create a separate Security Group;
  # otherwise we place the cluster in two SGs - one that is created by EKS, the other one that the module creates.
  # See https://docs.aws.amazon.com/eks/latest/userguide/sec-group-reqs.html for more details.
  create_security_group = false

  # This is to test `allowed_security_group_ids` and `allowed_cidr_blocks`
  # In a real cluster, these should be some other (existing) Security Groups and CIDR blocks to allow access to the cluster
  allowed_security_group_ids = [var.default_security_group_id]
  allowed_cidr_blocks        = [var.vpc_cidr_block]

  # For manual testing. In particular, set `false` if local configuration/state
  # has a cluster but the cluster was deleted by nightly cleanup, in order for
  # `terraform destroy` to succeed.
  apply_config_map_aws_auth = var.apply_config_map_aws_auth

  context                            = module.this.context
  kube_exec_auth_enabled             = true
  kube_exec_auth_aws_profile_enabled = true
  kube_exec_auth_aws_profile         = "ondc-prod"

}


module "eks_node_group" {
  source  = "cloudposse/eks-node-group/aws"
  version = "2.4.0"

  subnet_ids        = var.subnet_ids
  cluster_name      = module.eks_cluster.eks_cluster_id
  instance_types    = var.instance_types
  desired_size      = var.desired_size
  min_size          = var.min_size
  max_size          = var.max_size
  kubernetes_labels = var.kubernetes_labels

  # Prevent the node groups from being created before the Kubernetes aws-auth ConfigMap
  module_depends_on     = module.eks_cluster.kubernetes_config_map_id
  node_role_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
    "arn:aws:iam::aws:policy/AmazonElasticFileSystemReadOnlyAccess",
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
    "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy",
    "arn:aws:iam::aws:policy/AmazonSSMFullAccess",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess",
    "arn:aws:iam::aws:policy/AmazonElasticFileSystemFullAccess",
    "arn:aws:iam::aws:policy/AmazonEC2FullAccess",
    aws_iam_policy.ecr.arn,
  ]
  context                    = module.this.context
  cluster_autoscaler_enabled = true

}

# another node group with r5.large instance type and tainted with redis=true
module "eks_node_group_redis" {
  source                = "cloudposse/eks-node-group/aws"
  version               = "2.4.0"
  name                  = "${module.this.name}-redis"
  subnet_ids            = var.subnet_ids
  cluster_name          = module.eks_cluster.eks_cluster_id
  instance_types        = ["r5.xlarge"]
  desired_size          = 1
  min_size              = 1
  max_size              = 1
  kubernetes_taints     = [{ key = "es", value = "true", effect = "NO_SCHEDULE" }]
  block_device_mappings = [
    {
      "delete_on_termination" : true,
      "device_name" : "/dev/xvda",
      "encrypted" : true,
      "volume_size" : 100,
      "volume_type" : "gp2"
    }
  ]

  # Prevent the node groups from being created before the Kubernetes aws-auth ConfigMap
  module_depends_on     = module.eks_cluster.kubernetes_config_map_id
  node_role_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
    "arn:aws:iam::aws:policy/AmazonElasticFileSystemReadOnlyAccess",
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
    "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy",
    "arn:aws:iam::aws:policy/AmazonSSMFullAccess",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess",
    "arn:aws:iam::aws:policy/AmazonElasticFileSystemFullAccess",
    "arn:aws:iam::aws:policy/AmazonEC2FullAccess",
    #    aws_iam_policy.ecr.arn,
  ]
  context                    = module.this.context
  cluster_autoscaler_enabled = true

}
#
## redis worker node group on spot instance on t3.2xlarge
#module "eks_node_group_redis_spot" {
#  source                     = "cloudposse/eks-node-group/aws"
#  version                    = "2.4.0"
#  name                       = "${module.this.name}-redis-spot"
#  subnet_ids                 = var.subnet_ids
#  cluster_name               = module.eks_cluster.eks_cluster_id
#  instance_types             = ["c5.4xlarge"]
#  desired_size               = 3
#  min_size                   = 3
#  max_size                   = 3
#  kubernetes_taints          = [{ key = "redis-worker", value = "true", effect = "NO_SCHEDULE" }]
#  capacity_type              = "SPOT"
#  cluster_autoscaler_enabled = true
#
#  # Prevent the node groups from being created before the Kubernetes aws-auth ConfigMap
#  module_depends_on     = module.eks_cluster.kubernetes_config_map_id
#  node_role_policy_arns = [
#    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
#    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
#    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
#    "arn:aws:iam::aws:policy/AmazonElasticFileSystemReadOnlyAccess",
#    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
#    "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy",
#    "arn:aws:iam::aws:policy/AmazonSSMFullAccess",
#    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess",
#    "arn:aws:iam::aws:policy/AmazonElasticFileSystemFullAccess",
#    "arn:aws:iam::aws:policy/AmazonEC2FullAccess",
#    aws_iam_policy.ecr.arn,
#  ]
#  context = module.this.context
#}


# and pass it to worker nodes
resource "aws_iam_policy" "ecr" {
  name        = "ecr-${module.this.namespace}-${module.this.stage}"
  description = "Allow ECR access"
  policy      = file("${path.module}/ecr-policy.json")
}