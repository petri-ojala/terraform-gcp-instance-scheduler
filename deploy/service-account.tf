#
# Service Account for Cloud Run container

resource "google_service_account" "run" {
  account_id   = lookup(var.scheduler.sa_run, "id", null)
  display_name = lookup(var.scheduler.sa_run, "name", null)
  description  = lookup(var.scheduler.sa_run, "description", null)
}

resource "google_cloud_run_service_iam_member" "run" {
  location = google_cloud_run_service.scheduler.location
  project  = google_cloud_run_service.scheduler.project
  service  = google_cloud_run_service.scheduler.name
  role     = "roles/run.admin"
  member   = "serviceAccount:${google_service_account.run.email}"
}

#
# Give Cloud Run permissions to manage instances on each GCP project

resource "google_project_iam_custom_role" "run_compute_engine" {
  for_each = toset(split(",", var.scheduler.env.scheduler_projects))

  project     = each.key
  role_id     = lookup(var.scheduler.sa_run, "role_id", null)
  title       = lookup(var.scheduler.sa_run, "role_title", null)
  description = lookup(var.scheduler.sa_run, "role_description", null)
  permissions = [
    # Schedule instances
    "compute.zones.list",
    "compute.instances.list",
    "compute.instances.start",
    "compute.instances.stop",
  ]
}

resource "google_project_iam_member" "run_compute_engine" {
  for_each = toset(split(",", var.scheduler.env.scheduler_projects))

  project = each.key
  role    = google_project_iam_custom_role.run_compute_engine[each.key].name
  member  = "serviceAccount:${google_service_account.run.email}"
}

#
# Service Account for Cloud Scheduler to invoke Cloud Run

resource "google_service_account" "scheduler" {
  account_id   = lookup(var.scheduler.sa_scheduler, "id", null)
  display_name = lookup(var.scheduler.sa_scheduler, "name", null)
  description  = lookup(var.scheduler.sa_scheduler, "description", null)
}

resource "google_cloud_run_service_iam_member" "scheduler" {
  location = google_cloud_run_service.scheduler.location
  project  = google_cloud_run_service.scheduler.project
  service  = google_cloud_run_service.scheduler.name
  role     = "roles/run.invoker"
  member   = "serviceAccount:${google_service_account.scheduler.email}"
}
