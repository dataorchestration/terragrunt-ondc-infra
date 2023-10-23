variable "map_of_connector_configuration" {
  description = "this contains debezium connector configuration"
  type        = map(string)
}
variable "kafka_bootstrap_servers" {
  description = "kafka bootstrap servers"
}
variable "vpc_default_security_group" {
  description = "default vpc security group"
}
variable "subnets" {
  description = "subnets"
  type        = list(string)
}
variable "aws_mskconnect_custom_plugin_arn" {
  description = "custom plugin arn"
}
variable "aws_mskconnect_custom_plugin_latest_revision" {
  description = "revision of the custom plugin"
}
variable "connector_name" {
  description = "self descriptive name"
}
variable "cloudwatch_log_group" {
  description = ""
}
