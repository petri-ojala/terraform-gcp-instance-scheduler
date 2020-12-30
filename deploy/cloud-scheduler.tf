#
# Enable Cloud Scheduler API

resource "google_project_service" "scheduler" {
  project = var.gcp.project
  service = "cloudscheduler.googleapis.com"
}

#
# Create Cloud Scheduler job to execute Cloud Run container

resource "google_cloud_scheduler_job" "scheduler" {
  region           = var.gcp.region
  name             = lookup(var.scheduler.scheduler, "name", null)
  description      = lookup(var.scheduler.scheduler, "description", null)
  schedule         = lookup(var.scheduler.scheduler, "schedule", null)
  time_zone        = lookup(var.scheduler.scheduler, "time_zone", null)
  attempt_deadline = lookup(var.scheduler.scheduler, "attempt_deadline", null)

  http_target {
    http_method = "GET"
    uri         = "${google_cloud_run_service.scheduler.status[0].url}/"

    oidc_token {
      service_account_email = google_service_account.scheduler.email
      #      audience              = google_cloud_run_service.scheduler.status[0].url
    }
  }

  depends_on = [
    google_project_service.scheduler
  ]
}

