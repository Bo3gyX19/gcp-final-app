# ──────────────────────────────────────────────
# GCS Bucket for Terraform Remote State
# ──────────────────────────────────────────────
# Created during initial local apply, then migrated to via backend config

resource "google_storage_bucket" "tfstate" {
  name          = local.tfstate_bucket_name
  location      = var.location
  force_destroy = false # Protect state bucket from accidental deletion

  uniform_bucket_level_access = true

  versioning {
    enabled = true # Keep history of state changes
  }

  labels = merge(
    local.common_labels,
    {
      purpose = "terraform-state"
    }
  )

  depends_on = [google_project_service.apis]
}
