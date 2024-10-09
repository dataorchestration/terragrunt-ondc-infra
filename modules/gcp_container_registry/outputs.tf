output "repository_urls" {
  value = {for repo in google_artifact_registry_repository.demo_repo : repo.repository_id => "asia-south1-docker.pkg.dev/ondc-ref-buyer-app/${repo.repository_id}"}
}