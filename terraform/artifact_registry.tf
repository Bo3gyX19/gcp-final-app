# ──────────────────────────────────────────────
# Artifact Registry — Docker images
# ──────────────────────────────────────────────

resource "google_artifact_registry_repository" "rag_repo" {
  location      = var.region
  repository_id = "rag-repo"
  description   = "Docker images for RAG services"
  format        = "DOCKER"
  labels        = local.common_labels

  # Cleanup policy — keep only the 5 most recent tags to save cost
  cleanup_policy_dry_run = false

  cleanup_policies {
    id     = "keep-recent"
    action = "KEEP"
    most_recent_versions {
      keep_count = 5
    }
  }

  depends_on = [google_project_service.apis]
}
