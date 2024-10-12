output "security_policy_id" {
  description = "The ID of the created Cloud Armor security policy"
  value       = google_compute_security_policy.policy.id
}