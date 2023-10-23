output "msk_worker_configuration_arn" {
  value = aws_mskconnect_worker_configuration.this[0].arn
}
output "msk_worker_configuration_latest_revision" {
  value = aws_mskconnect_worker_configuration.this[0].latest_revision
}

output "aws_mskconnect_custom_plugin_arn" {
  value = aws_mskconnect_custom_plugin.this.arn
}
output "aws_mskconnect_custom_plugin_state" {
  value = aws_mskconnect_custom_plugin.this.state
}
output "aws_mskconnect_custom_plugin_latest_revision" {
  value = aws_mskconnect_custom_plugin.this.latest_revision
}


