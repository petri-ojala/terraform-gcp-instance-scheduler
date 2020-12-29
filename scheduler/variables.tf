#
# GCP credentials

variable "gcp" {
  type = object({
    project          = string
    region           = string
    credentials_file = string
  })
  description = "GCP Credentials"
}

#
# Repository

variable "repository" {
  type = object({
    id          = string
    description = string
    format      = string
  })
  description = "Artifact repository"
}
