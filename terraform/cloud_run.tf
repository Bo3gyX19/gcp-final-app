# ──────────────────────────────────────────────
# Cloud Run — Ingestor + Agent API (Scale-to-Zero)
# ──────────────────────────────────────────────

# ── Ingestor Service ──
resource "google_cloud_run_v2_service" "ingestor" {
  name     = local.ingestor_service_name
  location = var.region

  deletion_protection = false

  template {
    service_account = google_service_account.ingestor_sa.email

    # Scale to zero to avoid idle costs
    scaling {
      min_instance_count = 0
      max_instance_count = 3
    }

    containers {
      image = local.ingestor_image

      env {
        name  = "PROJECT_ID"
        value = var.project_id
      }

      resources {
        limits = {
          cpu    = "1"
          memory = "512Mi"
        }
      }
    }

    # Route traffic through VPC for Private Google Access
    vpc_access {
      connector = google_vpc_access_connector.connector.id
      egress    = "ALL_TRAFFIC"
    }

    timeout = "300s"
  }

  depends_on = [
    google_project_service.apis,
    google_artifact_registry_repository.rag_repo,
  ]

  lifecycle {
    ignore_changes = [
      template[0].containers[0].image, # Image tag managed by Cloud Build
    ]
  }
}

# ── Agent API Service ──
resource "google_cloud_run_v2_service" "agent" {
  name     = local.agent_service_name
  location = var.region

  deletion_protection = false

  template {
    service_account = google_service_account.api_agent_sa.email

    scaling {
      min_instance_count = 0
      max_instance_count = 5
    }

    containers {
      image = local.agent_image

      env {
        name  = "PROJECT_ID"
        value = var.project_id
      }

      resources {
        limits = {
          cpu    = "1"
          memory = "512Mi"
        }
      }
    }

    vpc_access {
      connector = google_vpc_access_connector.connector.id
      egress    = "ALL_TRAFFIC"
    }

    timeout = "60s"
  }

  depends_on = [
    google_project_service.apis,
    google_artifact_registry_repository.rag_repo,
  ]

  lifecycle {
    ignore_changes = [
      template[0].containers[0].image,
    ]
  }
}

# ── Allow unauthenticated access to Agent API (for testing) ──
# Remove this in production and use IAP or API Gateway instead
resource "google_cloud_run_v2_service_iam_member" "agent_public" {
  project  = var.project_id
  location = var.region
  name     = google_cloud_run_v2_service.agent.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}
