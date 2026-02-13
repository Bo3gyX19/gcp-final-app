# ──────────────────────────────────────────────
# Eventarc — trigger Ingestor on GCS upload
# ──────────────────────────────────────────────

resource "google_eventarc_trigger" "doc_upload" {
  name     = "doc-upload-trigger"
  location = var.eventarc_location

  # Use dedicated SA (not default compute SA)
  service_account = google_service_account.ingestor_sa.email

  matching_criteria {
    attribute = "type"
    value     = "google.cloud.storage.object.v1.finalized"
  }
  matching_criteria {
    attribute = "bucket"
    value     = google_storage_bucket.docs.name
  }

  destination {
    cloud_run_service {
      service = google_cloud_run_v2_service.ingestor.name
      region  = var.region
    }
  }

  depends_on = [
    google_project_service.apis,
    google_project_iam_member.gcs_pubsub_publisher,
    google_project_iam_member.eventarc_run_invoker,
    google_project_iam_member.eventarc_event_receiver,
    google_storage_bucket_iam_member.eventarc_bucket_access,
  ]
}

# Grant Eventarc service account permission to read the bucket
resource "google_storage_bucket_iam_member" "eventarc_bucket_access" {
  bucket = google_storage_bucket.docs.name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${google_service_account.ingestor_sa.email}"
}
