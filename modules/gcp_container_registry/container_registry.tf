terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "5.34.0"
    }
  }
}

variable "repo_names" {
  default = ""
}
resource "google_artifact_registry_repository" "demo_repo" {
  count = length(var.repo_names)
  location      = var.location
  repository_id = var.repo_names[count.index]
  description   = var.repo_names[count.index]
  format        = "DOCKER"
}

data "google_iam_policy" "admin" {
  binding {
    role    = "roles/artifactregistry.admin"
    members = var.members
  }
}

resource "google_artifact_registry_repository_iam_policy" "policy" {
  count       = length(var.repo_names)
  repository  = google_artifact_registry_repository.demo_repo[count.index].name
  policy_data = data.google_iam_policy.admin.policy_data
}

provider "google" {
    region = var.location
    project = var.project
}