# ──────────────────────────────────────────────
# Cloud Storage — Documents Landing Zone
# ──────────────────────────────────────────────

resource "google_storage_bucket" "docs" {
  name          = local.docs_bucket_name
  location      = var.location
  force_destroy = true # For dev convenience; disable in prod
  labels        = local.common_labels

  uniform_bucket_level_access = true # Best practice for security

  versioning {
    enabled = false
  }

  lifecycle_rule {
    condition {
      age = 90 # Delete raw PDFs after 90 days (they are already indexed)
    }
    action {
      type = "Delete"
    }
  }

  depends_on = [google_project_service.apis]
}
