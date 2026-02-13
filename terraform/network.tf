# ──────────────────────────────────────────────
# VPC & Private Google Access
# ──────────────────────────────────────────────

resource "google_compute_network" "rag_vpc" {
  name                    = "rag-vpc"
  auto_create_subnetworks = false
  depends_on              = [google_project_service.apis]
}

resource "google_compute_subnetwork" "rag_subnet" {
  name                     = "rag-subnet"
  ip_cidr_range            = "10.0.0.0/24"
  region                   = var.region
  network                  = google_compute_network.rag_vpc.id
  private_ip_google_access = true # ← Traffic to Google APIs stays internal
}

# Serverless VPC Access connector — allows Cloud Run to use the VPC
resource "google_vpc_access_connector" "connector" {
  name          = "rag-vpc-connector"
  region        = var.region
  network       = google_compute_network.rag_vpc.name
  ip_cidr_range = "10.8.0.0/28"
  min_instances = 2
  max_instances = 3

  depends_on = [google_project_service.apis]
}

# Firewall: allow internal traffic only
resource "google_compute_firewall" "allow_internal" {
  name    = "rag-allow-internal"
  network = google_compute_network.rag_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }
  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }
  allow {
    protocol = "icmp"
  }

  source_ranges = ["10.0.0.0/24", "10.8.0.0/28"]
}

# Deny all egress to the internet (traffic goes only to Google APIs via PGA)
# NOTE: This is strict. Uncomment only if you are sure all deps are Google-internal.
# resource "google_compute_firewall" "deny_egress" {
#   name      = "rag-deny-egress"
#   network   = google_compute_network.rag_vpc.name
#   direction = "EGRESS"
#   priority  = 1000
#
#   deny {
#     protocol = "all"
#   }
#
#   destination_ranges = ["0.0.0.0/0"]
# }
