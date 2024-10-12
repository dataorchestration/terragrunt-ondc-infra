variable "project_id" {
  description = "The ID of the project in which the resource belongs"
  type        = string
}

variable "security_policy_name" {
  description = "Name of the Cloud Armor security policy"
  type        = string
  default     = "lb-security-policy"
}

# variable "custom_header_name" {
#   description = "Name of the custom header required for requests"
#   type        = string
#   default     = "X-Custom-Auth"
# }
#
# variable "custom_header_value" {
#   description = "Value of the custom header required for requests"
#   type        = string
#   default     = "SecretValue123"
# }
