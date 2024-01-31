include {
  path = find_in_parent_folders()
}

locals {
  # Automatically load environment-level variables
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  region_vars = read_terragrunt_config(find_in_parent_folders("region.hcl"))
}


terraform {
  source = "../../../../../modules//kafka-connectors"
}


dependency "kafka-worker" {
  config_path = "../kafka-worker-debezium"
}
dependency "default_network" {
  config_path = "../network"
}


inputs = {
  namespace                  = local.environment_vars.locals.namespace
  stage                      = local.environment_vars.locals.stage
  vpc_id                     = dependency.default_network.outputs.default_vpc
  kafka_bootstrap_servers    = "b-3.kafkaonsearchcluster.u3k9qd.c2.kafka.ap-south-1.amazonaws.com:9092,b-2.kafkaonsearchcluster.u3k9qd.c2.kafka.ap-south-1.amazonaws.com:9092,b-4.kafkaonsearchcluster.u3k9qd.c2.kafka.ap-south-1.amazonaws.com:9092"
  vpc_default_security_group = dependency.default_network.outputs.aws_default_security_group
  subnets                    = [
    dependency.default_network.outputs.default_subnet, dependency.default_network.outputs.default_subnetb
  ]

  connector_name       = "s3-on-search-cluster-gateway-payload"
  cloudwatch_log_group = "s3-on-search-cluster-gateway-payload"
  name = "s3-on-search-cluster-gateway-payload"

  aws_mskconnect_custom_plugin_arn             = dependency.kafka-worker.outputs.aws_mskconnect_custom_plugin_arn
  aws_mskconnect_custom_plugin_latest_revision = 1
  map_of_connector_configuration               = tomap({
    "connector.class"             = "io.confluent.connect.s3.S3SinkConnector"
    "tasks.max"                   = "1"
    "topics.regex"                = "on_search_cluster_gateway_payload"
    "s3.bucket.name"              = "ondc-rds-analytics-data-export"
    "s3.region"                   = "ap-south-1"
    "s3.part.size"                = "10242880"
    "flush.size"                  = "1000000"
    "storage.class"               = "io.confluent.connect.s3.storage.S3Storage"
    "format.class"                = "io.confluent.connect.s3.format.bytearray.ByteArrayFormat"
    "value.converter"             = "org.apache.kafka.connect.converters.ByteArrayConverter"
    "schema.compatibility"        = "NONE"
    "partitioner.class"           = "io.confluent.connect.storage.partitioner.TimeBasedPartitioner"
    "locale"                      = "en"
    "timezone"                    = "UTC"
    "path.format"                 = "'server_date'=YYYY-MM-dd/'hour'=HH"
    "partition.duration.ms"       = "900000"
    "rotate.interval.ms"          = "900000"
    "rotate.schedule.interval.ms" = "1800000"
    "timestamp.extractor"         = "Wallclock"
    "behavior.on.null.values"     = "IGNORE"
    "max.partition.fetch.bytes"   = "52428800"
    "s3.compression.type"         = "gzip"
    "s3.compression.level"        = "9"
  })
}


