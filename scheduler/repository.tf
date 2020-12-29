#
# Create Google Cloud Artifact Repository

#
# Enable Artifact API

resource "google_project_service" "repo" {
  project = var.gcp.project
  service = "artifactregistry.googleapis.com"
}

#
# Create Artifact Repository

resource "google_artifact_registry_repository" "repo" {
  provider = google-beta

  location      = var.gcp.region
  repository_id = var.repository.id
  description   = var.repository.description
  format        = var.repository.format

  depends_on = [google_project_service.repo]
}

#
# GCP provider

provider "google" {
  credentials = file(var.gcp.credentials_file)
  project     = var.gcp.project
  region      = var.gcp.region
}

provider "google-beta" {
  credentials = file(var.gcp.credentials_file)
  project     = var.gcp.project
  region      = var.gcp.region
}

#
# Version requirements

terraform {
  required_version = "~> 0.14"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 3.51"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 3.51"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0.0"
    }
  }
}
