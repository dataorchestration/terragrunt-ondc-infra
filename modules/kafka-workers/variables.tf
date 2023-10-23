variable "create" {
  description = ""
}

variable "create_connect_worker_configuration" {
  type = bool
}

variable "connect_worker_config_name" {
  description = "connector-name"
}
variable "connect_worker_config_description" {
  description = "connector-description"
}
variable "connect_worker_config_properties_file_content" {
  description = ""
}

variable "connector_name" {
  description = ""
}
variable "connector_description" {
  description = ""
}
variable "content_type" {
  default = "ZIP"
}
variable "connector_create_timeout" {
  default = "10m"
}
variable "connector_jar_s3_file_key" {
  description = ""
}
variable "connector_zip_s3_file_path" {
  description = "connector path locally"
}
variable "connector_jar_s3_bucket_name" {
  description = "bucket to upload to"
}
variable "connector_external_url" {
  description = "maven url to show the jar path"
}
variable "connector_jar_s3_bucket_arn" {
 description = "arn of the bucket required for connectors"
}