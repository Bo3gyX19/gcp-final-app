# ──────────────────────────────────────────────
# Locals — computed / derived values
# ──────────────────────────────────────────────

locals {
  # If the user didn't specify a bucket name, generate one from the project id
  docs_bucket_name    = var.docs_bucket_name != "" ? var.docs_bucket_name : "${var.project_id}-docs-landing-zone"
  tfstate_bucket_name = var.tfstate_bucket_name != "" ? var.tfstate_bucket_name : "${var.project_id}-tfstate"

  # Standard labels applied to every resource
  common_labels = {
    project     = "enterprise-rag"
    environment = var.environment
    managed_by  = "terraform"
  }

  # Service names
  ingestor_service_name = "rag-ingestor"
  agent_service_name    = "rag-agent"

  # Container image paths (Artifact Registry)
  ingestor_image = "${var.region}-docker.pkg.dev/${var.project_id}/rag-repo/${local.ingestor_service_name}:latest"
  agent_image    = "${var.region}-docker.pkg.dev/${var.project_id}/rag-repo/${local.agent_service_name}:latest"
}
