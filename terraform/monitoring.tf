# ──────────────────────────────────────────────
# Cloud Monitoring — Dashboard
# ──────────────────────────────────────────────

resource "google_monitoring_dashboard" "rag_dashboard" {
  dashboard_json = jsonencode({
    displayName = "Enterprise RAG System"

    mosaicLayout = {
      columns = 12

      tiles = [
        # ── Tile 1: Cloud Run Request Count ──
        {
          width  = 6
          height = 4
          widget = {
            title = "Cloud Run — Request Count"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"cloud_run_revision\" AND metric.type=\"run.googleapis.com/request_count\""
                    aggregation = {
                      alignmentPeriod  = "60s"
                      perSeriesAligner = "ALIGN_RATE"
                    }
                  }
                }
                plotType = "LINE"
              }]
            }
          }
        },
        # ── Tile 2: Cloud Run Latency ──
        {
          xPos   = 6
          width  = 6
          height = 4
          widget = {
            title = "Cloud Run — Request Latency (p99)"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"cloud_run_revision\" AND metric.type=\"run.googleapis.com/request_latencies\""
                    aggregation = {
                      alignmentPeriod  = "60s"
                      perSeriesAligner = "ALIGN_PERCENTILE_99"
                    }
                  }
                }
                plotType = "LINE"
              }]
            }
          }
        },
        # ── Tile 3: Cloud Run Instance Count (scale-to-zero check) ──
        {
          yPos   = 4
          width  = 6
          height = 4
          widget = {
            title = "Cloud Run — Active Instances"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"cloud_run_revision\" AND metric.type=\"run.googleapis.com/container/instance_count\""
                    aggregation = {
                      alignmentPeriod  = "60s"
                      perSeriesAligner = "ALIGN_MEAN"
                    }
                  }
                }
                plotType = "STACKED_AREA"
              }]
            }
          }
        },
        # ── Tile 4: Cloud Build Status ──
        {
          yPos   = 4
          xPos   = 6
          width  = 6
          height = 4
          widget = {
            title = "Cloud Build — Build Count by Status"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"build\" AND metric.type=\"cloudbuild.googleapis.com/build_count\""
                    aggregation = {
                      alignmentPeriod  = "3600s"
                      perSeriesAligner = "ALIGN_SUM"
                      groupByFields    = ["metric.label.status"]
                    }
                  }
                }
                plotType = "STACKED_BAR"
              }]
            }
          }
        },
        # ── Tile 5: Vertex AI Token Usage / Quota ──
        {
          yPos   = 8
          width  = 6
          height = 4
          widget = {
            title = "Vertex AI — Prediction Request Count"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"aiplatform.googleapis.com/Publisher\" AND metric.type=\"aiplatform.googleapis.com/publisher/online_serving/request_count\""
                    aggregation = {
                      alignmentPeriod  = "60s"
                      perSeriesAligner = "ALIGN_RATE"
                    }
                  }
                }
                plotType = "LINE"
              }]
            }
          }
        },
        # ── Tile 6: BigQuery Slots / Query Count ──
        {
          yPos   = 8
          xPos   = 6
          width  = 6
          height = 4
          widget = {
            title = "BigQuery — Query Count"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"bigquery_project\" AND metric.type=\"bigquery.googleapis.com/query/count\""
                    aggregation = {
                      alignmentPeriod  = "300s"
                      perSeriesAligner = "ALIGN_SUM"
                    }
                  }
                }
                plotType = "LINE"
              }]
            }
          }
        }
      ]
    }
  })

  depends_on = [google_project_service.apis]
}
