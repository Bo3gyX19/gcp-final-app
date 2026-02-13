# ──────────────────────────────────────────────
# Provider & Backend configuration
# ──────────────────────────────────────────────

terraform {
  required_version = ">= 1.5"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.0, < 7.0"
    }
  }

  # ── Remote Backend (GCS) ──
  # Uncomment AFTER creating the bucket with:
  #   gsutil mb -p <PROJECT_ID> -l US gs://<PROJECT_ID>-tfstate
  #   gsutil versioning set on gs://<PROJECT_ID>-tfstate
  #
  # backend "gcs" {
  #   bucket = "<PROJECT_ID>-tfstate"
  #   prefix = "terraform/state"
  # }
}

provider "google" {
  project = var.project_id
  region  = var.region
}
