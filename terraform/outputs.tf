# ──────────────────────────────────────────────
# Outputs
# ──────────────────────────────────────────────

output "docs_bucket_name" {
  description = "Name of the GCS bucket for PDF uploads"
  value       = google_storage_bucket.docs.name
}

output "agent_api_url" {
  description = "Public URL of the RAG Agent API"
  value       = google_cloud_run_v2_service.agent.uri
}

output "ingestor_url" {
  description = "URL of the Ingestor Cloud Run service"
  value       = google_cloud_run_v2_service.ingestor.uri
}

output "artifact_registry_repo" {
  description = "Artifact Registry repository path"
  value       = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.rag_repo.repository_id}"
}

output "vpc_connector_name" {
  description = "Serverless VPC Access connector"
  value       = google_vpc_access_connector.connector.name
}

output "ingestor_service_account" {
  description = "Service account email for the Ingestor"
  value       = google_service_account.ingestor_sa.email
}

output "agent_service_account" {
  description = "Service account email for the Agent API"
  value       = google_service_account.api_agent_sa.email
}
