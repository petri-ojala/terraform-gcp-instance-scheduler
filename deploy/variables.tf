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
# Cloud Run application

variable "scheduler" {
  type = object({
    repository_id = string
    name          = string
    image         = string
    env           = map(string)
    runtime       = map(string)
    sa_run        = map(string)
    sa_scheduler  = map(string)
    scheduler     = map(string)
  })
}
