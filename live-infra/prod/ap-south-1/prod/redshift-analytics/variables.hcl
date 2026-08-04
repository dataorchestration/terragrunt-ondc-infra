locals {
  name = "analytics"

  node_type       = "ra3.large"
  cluster_type    = "single-node"
  number_of_nodes = 1

  database_name = "analytics"
  admin_user    = "admin"

  publicly_accessible = true
  encrypted           = true

  automated_snapshot_retention_period = 7
  skip_final_snapshot                 = false
  final_snapshot_identifier           = "ondc-prod-analytics-final-snapshot"
}