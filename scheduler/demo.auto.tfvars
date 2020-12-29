#
# Example configuration parameters for GCP Repository

#
# GCP region and credentials

gcp = {
  project          = "pojala-gcp-payground"
  region           = "europe-west1"
  credentials_file = "./pojala-gcp-playground.json"
}

#
# GCP Artifact repository details

repository = {
  id          = "gcp-scheduler-repo"
  description = "GCP Instance Scheduler Repository"
  format      = "DOCKER"
}
