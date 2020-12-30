#
# Deploy GCP Instance Scheduler to Cloud Run

resource "google_cloud_run_service" "scheduler" {
  name     = var.scheduler.name
  location = var.gcp.region

  template {
    spec {
      containers {
        # Allow full image location or just the image name in our default repository
        image = length(regexall("/", var.scheduler.image)) > 0 ? var.scheduler.image : "${var.gcp.region}-docker.pkg.dev/${var.gcp.project}/${var.scheduler.repository_id}/${var.scheduler.image}"

        dynamic "env" {
          for_each = var.scheduler.env
          content {
            name  = env.key
            value = env.value
          }
        }
      }

      service_account_name = google_service_account.run.email
    }
    metadata {
      annotations = var.scheduler.runtime
    }
  }
  traffic {
    percent         = 100
    latest_revision = true
  }
}

#
# Cloud Run URL

output "url" {
  value = google_cloud_run_service.scheduler.status[0].url
}
