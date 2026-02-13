# ──────────────────────────────────────────────
# Enable required GCP APIs
# ──────────────────────────────────────────────

resource "google_project_service" "apis" {
  for_each = toset([
    "bigquery.googleapis.com",
    "bigqueryconnection.googleapis.com",
    "aiplatform.googleapis.com",
    "run.googleapis.com",
    "eventarc.googleapis.com",
    "artifactregistry.googleapis.com",
    "cloudbuild.googleapis.com",
    "storage.googleapis.com",
    "iam.googleapis.com",
    "compute.googleapis.com",   # Required for VPC / networking
    "vpcaccess.googleapis.com", # Serverless VPC Access
    "monitoring.googleapis.com",
    "logging.googleapis.com",
    "secretmanager.googleapis.com",
  ])

  project                    = var.project_id
  service                    = each.key
  disable_dependent_services = false
  disable_on_destroy         = false
}
