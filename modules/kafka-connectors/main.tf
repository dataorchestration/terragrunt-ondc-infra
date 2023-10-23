resource "aws_mskconnect_connector" "msk-connector" {
  name = var.connector_name

  kafkaconnect_version = "2.7.1"

  capacity {
    autoscaling {
      # we dont need autoscaling in case of debezium, though we will keep it for any future connectors
      mcu_count        = 1
      min_worker_count = 1
      max_worker_count = 2

      scale_in_policy {
        cpu_utilization_percentage = 20
      }

      scale_out_policy {
        cpu_utilization_percentage = 80
      }
    }
  }

  connector_configuration = var.map_of_connector_configuration

  kafka_cluster {
    apache_kafka_cluster {
      bootstrap_servers = var.kafka_bootstrap_servers

      vpc {
        security_groups = [var.vpc_default_security_group]
        subnets         = var.subnets
      }
    }
  }

  log_delivery {
    worker_log_delivery {
      cloudwatch_logs {
        enabled   = true
        log_group = var.cloudwatch_log_group
      }
    }
  }

  kafka_cluster_client_authentication {
    authentication_type = "NONE"
  }

  kafka_cluster_encryption_in_transit {
    encryption_type = "PLAINTEXT"
  }

  plugin {
    custom_plugin {
      arn      = var.aws_mskconnect_custom_plugin_arn
      revision = var.aws_mskconnect_custom_plugin_latest_revision
    }
  }

  service_execution_role_arn = aws_iam_role.allow-kafka-connect-to-access-msk-s3.arn
  depends_on                 = [aws_cloudwatch_log_group.debezium_cloudwatch_logs]
}

data "aws_iam_policy_document" "assume-kafka-connect" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["kafka.amazonaws.com"]
    }
  }

  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["kafkaconnect.amazonaws.com"]
    }
  }

}

resource "aws_iam_role" "allow-kafka-connect-to-access-msk-s3" {
  name                = "allow-connect-for-${var.connector_name}"
  assume_role_policy  = data.aws_iam_policy_document.assume-kafka-connect.json
  managed_policy_arns = ["arn:aws:iam::aws:policy/AmazonMSKFullAccess", "arn:aws:iam::aws:policy/AmazonS3FullAccess"]
}

resource "aws_cloudwatch_log_group" "debezium_cloudwatch_logs" {
  name              = var.cloudwatch_log_group
  retention_in_days = 7
}