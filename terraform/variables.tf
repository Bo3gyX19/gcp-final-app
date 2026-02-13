# ──────────────────────────────────────────────
# Variables — all configurable inputs
# ──────────────────────────────────────────────

variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "project_number" {
  description = "GCP Project Number (numeric)"
  type        = string
}

variable "region" {
  description = "Default compute region"
  type        = string
  default     = "us-central1"
}

variable "location" {
  description = "BigQuery / multi-region location"
  type        = string
  default     = "US"
}

variable "docs_bucket_name" {
  description = "Name of the GCS bucket for PDF uploads"
  type        = string
  default     = ""
}

variable "tfstate_bucket_name" {
  description = "Name of the GCS bucket for Terraform remote state"
  type        = string
  default     = ""
}

variable "environment" {
  description = "Environment label (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "eventarc_location" {
  description = "Eventarc trigger location (must match bucket location: 'us' for multi-region, or region like 'us-central1' for single region)"
  type        = string
  default     = "us"
}
