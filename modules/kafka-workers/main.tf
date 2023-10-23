resource "aws_mskconnect_custom_plugin" "this" {

  name         = var.connector_name
  description  = var.connector_description
  content_type = var.content_type

  location {
    s3 {
      bucket_arn = var.connector_jar_s3_bucket_arn
      file_key   = var.connector_jar_s3_file_key
    }
  }

  timeouts {
    create = var.connector_create_timeout
  }
}

module "label" {
  source  = "cloudposse/label/null"
  version = "0.25.0"

  context = module.this.context
}


resource "aws_mskconnect_worker_configuration" "this" {
  count = var.create && var.create_connect_worker_configuration ? 1 : 0

  name                    = var.connect_worker_config_name
  description             = var.connect_worker_config_description
  properties_file_content = var.connect_worker_config_properties_file_content

}


resource "null_resource" "debezium_connector" {
  provisioner "local-exec" {
    command = <<-EOT
        wget "${var.connector_external_url}" -O connector.tar.gz \
        && wget "https://dataorc-static-dev-s3-bucket.s3.ap-south-1.amazonaws.com/confluentinc-kafka-connect-s3-10.1.1.zip" -O s3-connector.zip \
        && unzip -o s3-connector.zip \
        && tar -zxvf connector.tar.gz \
        && zip -r -j "${var.connector_zip_s3_file_path}" $(tar tf connector.tar.gz) confluentinc-kafka-connect-s3-10.1.1/lib/* \
        && rm connector.tar.gz
    EOT
  }
  triggers = {
    always_run = "${timestamp()}"
  }
}

resource "aws_s3_object" "connector_jar" {
  bucket     = var.connector_jar_s3_bucket_name
  key        = var.connector_jar_s3_file_key
  source     = var.connector_zip_s3_file_path
  depends_on = [null_resource.debezium_connector]
}