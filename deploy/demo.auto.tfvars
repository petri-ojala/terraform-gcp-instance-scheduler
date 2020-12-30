#
# Example configuration parameters for GCP Repository

#
# GCP region and credentials

gcp = {
  project          = "pojala-gcp-playground"
  region           = "europe-west3"
  credentials_file = "./pojala-gcp-playground.json"
}

#
# GCP Artifact repository details

scheduler = {
  repository_id = "gcp-scheduler-repo"
  name          = "gcp-instance-scheduler"
  image         = "gcp_instance_scheduler"
  #
  # Define projects and zones for the Instance Scheduler
  env = {
    scheduler_projects = "pojala-gcp-playground"
    scheduler_zones    = "europe"
#    verbose            = "true"
  }
  #
  # We don't need to scale (cost control)
  runtime = {
    "autoscaling.knative.dev/maxScale" = "1"
  }
  #
  # Service Account for Cloud Run container
  sa_run = {
    "id"               = "instance-scheduler-run"
    "name"             = "GCP Instance Scheduler Cloud Run"
    "description"      = "GCP Instance Scheduler Cloud Run SA"
    "role_id"          = "instance_scheduler"
    "role_title"       = "Instance Scheduler"
    "role_description" = "Instance Scheduler"
  }
  #
  # Service Account for Cloud Scheduler to invoke Cloud Run
  sa_scheduler = {
    "id"          = "instance-scheduler"
    "name"        = "GCP Instance Scheduler"
    "description" = "GCP Instance Scheduler SA"
  }
  #
  # Cloud Scheduler configuration
  scheduler = {
    "name"             = "instance-scheduler"
    "description"      = "Instance Scheduler"
    "schedule"         = "*/10 * * * *"
    "time_zone"        = "Europe/Helsinki"
    "attempt_deadline" = "320s"
  }
}
