# ──────────────────────────────────────────────
# IAM — Dedicated Service Accounts (Least Privilege)
# ──────────────────────────────────────────────

# ── Ingestor SA ──
# Needs: read GCS objects, write to BigQuery, call Vertex AI embeddings
resource "google_service_account" "ingestor_sa" {
  account_id   = "rag-ingestor-sa"
  display_name = "RAG Ingestor Service Account"
  depends_on   = [google_project_service.apis]
}

resource "google_project_iam_member" "ingestor_roles" {
  for_each = toset([
    "roles/storage.objectViewer", # Read PDFs from GCS
    "roles/bigquery.dataEditor",  # Write embeddings to BQ
    "roles/bigquery.jobUser",     # Run insert jobs
    "roles/aiplatform.user",      # Call Vertex AI Embedding API
  ])
  project = var.project_id
  role    = each.key
  member  = "serviceAccount:${google_service_account.ingestor_sa.email}"
}

# ── Agent API SA ──
# Needs: read from BigQuery, run queries, call Gemini, use BQ connection
resource "google_service_account" "api_agent_sa" {
  account_id   = "rag-api-agent-sa"
  display_name = "RAG API Agent Service Account"
  depends_on   = [google_project_service.apis]
}

resource "google_project_iam_member" "agent_roles" {
  for_each = toset([
    "roles/bigquery.dataViewer",     # Read-only on tables
    "roles/bigquery.jobUser",        # Run SQL queries
    "roles/aiplatform.user",         # Call Gemini 2.0 Flash
    "roles/bigquery.connectionUser", # Use BQ ML remote connection
  ])
  project = var.project_id
  role    = each.key
  member  = "serviceAccount:${google_service_account.api_agent_sa.email}"
}

# ── Cloud Build SA permissions ──
# Cloud Build default SA needs to push images and deploy Cloud Run
resource "google_project_iam_member" "cloudbuild_roles" {
  for_each = toset([
    "roles/run.admin",               # Deploy Cloud Run services
    "roles/iam.serviceAccountUser",  # Act as service accounts
    "roles/artifactregistry.writer", # Push images
  ])
  project = var.project_id
  role    = each.key
  member  = "serviceAccount:${var.project_number}@cloudbuild.gserviceaccount.com"
}

# ── Eventarc — grant GCS agent Pub/Sub publisher ──
resource "google_project_iam_member" "gcs_pubsub_publisher" {
  project = var.project_id
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:service-${var.project_number}@gs-project-accounts.iam.gserviceaccount.com"
}

# ── Eventarc trigger SA — permission to invoke Cloud Run ──
resource "google_project_iam_member" "eventarc_run_invoker" {
  project = var.project_id
  role    = "roles/run.invoker"
  member  = "serviceAccount:${google_service_account.ingestor_sa.email}"
}

# ── Eventarc event receiver ──
resource "google_project_iam_member" "eventarc_event_receiver" {
  project = var.project_id
  role    = "roles/eventarc.eventReceiver"
  member  = "serviceAccount:${google_service_account.ingestor_sa.email}"
}
