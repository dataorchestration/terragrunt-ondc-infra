include {
  path = find_in_parent_folders()
}

locals {
  # Automatically load environment-level variables
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))


  region_vars = read_terragrunt_config(find_in_parent_folders("region.hcl"))
}


terraform {
  source = "../../../../../modules//kafka-workers"
}


inputs = {

  namespace = local.environment_vars.locals.namespace

  stage = local.environment_vars.locals.stage

  name = "kafka-connectors"

  create                                        = true
  create_connect_worker_configuration           = true
  connect_worker_config_name                    = "kafka-s3-worker-config"
  connect_worker_config_description             = "Kafka Connect configuration for debezium postgres"
  connector_name                                = "s3-dumps"
  connector_description                         = "Kafka Connect connector for debezium postgres"
  content_type                                  = "ZIP"
  connector_create_timeout                      = "15m"
  connector_jar_s3_file_key                     = "kafka-connect-jars/debezium-connector-postgres.zip"
  connector_zip_s3_file_path                    = "debezium-connector-postgres.zip"
  connector_jar_s3_bucket_name                  = "ondc-rds-analytics-data-export"
  connector_jar_s3_bucket_arn                   = "arn:aws:s3:::ondc-rds-analytics-data-export"
  connector_external_url                        = "https://repo1.maven.org/maven2/io/debezium/debezium-connector-postgres/1.9.5.Final/debezium-connector-postgres-1.9.5.Final-plugin.tar.gz"
  connect_worker_config_properties_file_content = <<-EOT
  key.converter=org.apache.kafka.connect.converters.ByteArrayConverter
  value.converter=org.apache.kafka.connect.converters.ByteArrayConverter
  EOT
}