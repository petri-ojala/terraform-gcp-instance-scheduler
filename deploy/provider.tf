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
