# ──────────────────────────────────────────────
# BigQuery — Vector Database for RAG
# ──────────────────────────────────────────────

resource "google_bigquery_dataset" "rag_dataset" {
  dataset_id = "enterprise_rag_v2"
  location   = var.location
  labels     = local.common_labels
  depends_on = [google_project_service.apis]
}

# Table for storing text chunks and their embeddings
resource "google_bigquery_table" "doc_embeddings" {
  dataset_id          = google_bigquery_dataset.rag_dataset.dataset_id
  table_id            = "doc_embeddings"
  deletion_protection = false
  labels              = local.common_labels

  schema = <<EOF
[
  {
    "name": "text_content",
    "type": "STRING",
    "mode": "REQUIRED"
  },
  {
    "name": "embedding",
    "type": "FLOAT",
    "mode": "REPEATED",
    "description": "768-dimensional vector from text-embedding-005"
  },
  {
    "name": "source_file",
    "type": "STRING",
    "mode": "NULLABLE"
  }
]
EOF
}

# ── BigQuery ↔ Vertex AI Connection ──
resource "google_bigquery_connection" "vertex_ai_conn" {
  connection_id = "vertex-ai-gen2-conn"
  location      = var.location
  friendly_name = "Connection to Vertex AI"
  cloud_resource {}
  depends_on = [google_project_service.apis]
}

# Grant the BQ connection SA permission to call Vertex AI
resource "google_project_iam_member" "bq_connection_iam" {
  project = var.project_id
  role    = "roles/aiplatform.user"
  member  = "serviceAccount:${google_bigquery_connection.vertex_ai_conn.cloud_resource[0].service_account_id}"

  depends_on = [google_bigquery_connection.vertex_ai_conn]
}

# ── BigQuery ML Model for Embeddings ──
# This creates the embedding model via Terraform so embeddings can be
# generated inside SQL (VECTOR_SEARCH + ML.GENERATE_EMBEDDING)
resource "google_bigquery_job" "create_embedding_model" {
  job_id   = "create-embedding-model-${formatdate("YYYYMMDDhhmmss", timestamp())}"
  location = var.location

  query {
    query              = <<-SQL
      CREATE MODEL IF NOT EXISTS `${var.project_id}.enterprise_rag_v2.embedding_model_005`
      REMOTE WITH CONNECTION `${var.project_id}.${var.location}.vertex-ai-gen2-conn`
      OPTIONS (ENDPOINT = 'text-embedding-005')
    SQL
    create_disposition = ""
    write_disposition  = ""
    use_legacy_sql     = false
  }

  depends_on = [
    google_bigquery_dataset.rag_dataset,
    google_bigquery_connection.vertex_ai_conn,
    google_project_iam_member.bq_connection_iam,
  ]

  lifecycle {
    ignore_changes = [job_id]
  }
}

