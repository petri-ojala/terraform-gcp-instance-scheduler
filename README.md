# GCP Instance Scheduler

Simple instance scheduler for Google Cloud that can be used in any container platform (e.g. Cloud Run or GKE), can be scheduled to run by e.g. Cloud Scheduler or Kubernetes CronJob, and instance schedules can be controlled by instance labels with crontab-like capabilities.

![Scheduler workflow](scheduler.png)

## Create the container image

`scheduler` directory contains the code for the scheduler container and Terraform template to create a GCP Artifact repository.  If you don't already have a repository available, you can
modify the `tfvars` example with your own content and run the Terraform templates to create one:

```hashicorp
$ terraform apply

An execution plan has been generated and is shown below.
Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # google_artifact_registry_repository.repo will be created
  + resource "google_artifact_registry_repository" "repo" {
      + create_time   = (known after apply)
      + description   = "GCP Instance Scheduler Repository"
      + format        = "DOCKER"
      + id            = (known after apply)
      + location      = "europe-west1"
      + name          = (known after apply)
      + project       = (known after apply)
      + repository_id = "gcp-scheduler-repo"
      + update_time   = (known after apply)
    }

  # google_project_service.repo will be created
  + resource "google_project_service" "repo" {
      + disable_on_destroy = true
      + id                 = (known after apply)
      + project            = "pojala-gcp-playground"
      + service            = "artifactregistry.googleapis.com"
    }

Plan: 2 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  + repository_url = "europe-west1-docker.pkg.dev/pojala-gcp-playground/gcp-scheduler-repo"

Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes

google_project_service.repo: Creating...
google_project_service.repo: Still creating... [10s elapsed]
google_project_service.repo: Still creating... [20s elapsed]
google_project_service.repo: Creation complete after 26s [id=pojala-gcp-playground/artifactregistry.googleapis.com]
google_artifact_registry_repository.repo: Creating...
google_artifact_registry_repository.repo: Still creating... [10s elapsed]
google_artifact_registry_repository.repo: Creation complete after 12s [id=projects/pojala-gcp-playground/locations/europe-west1/repositories/gcp-scheduler-repo]

Apply complete! Resources: 2 added, 0 changed, 0 destroyed.

Outputs:

repository_url = "europe-west1-docker.pkg.dev/pojala-gcp-playground/gcp-scheduler-repo"
```

Build the container with a tag referencing your repository, e.g.

```bash
$ docker build ./ -t europe-west1-docker.pkg.dev/pojala-gcp-playground/gcp-scheduler-repo/gcp_instance_scheduler:latest
Sending build context to Docker daemon  203.4MB
Step 1/9 : FROM golang:1.14 AS builder
1.14: Pulling from library/golang
6c33745f49b4: Pull complete
ef072fc32a84: Pull complete
c0afb8e68e0b: Pull complete
d599c07d28e6: Pull complete
c616e0dda35f: Pull complete
3e632de71d89: Pull complete
29116063284d: Pull complete
Digest: sha256:34e2b87146b59fa62de329e6cf766a0866707533d48bbcee8b2269cabf878b9c
Status: Downloaded newer image for golang:1.14
 ---> ae11962d94b7
Step 2/9 : WORKDIR /build
 ---> Running in d66f0bf99d72
Removing intermediate container d66f0bf99d72
 ---> 0d6e62fc993c
Step 3/9 : COPY scheduler.go .
 ---> a163ba134d5f
Step 4/9 : RUN go get -d -v ./...
 ---> Running in d90be934cda2
...
Removing intermediate container d90be934cda2
 ---> d8d93a14ce22
Step 5/9 : RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -a -o scheduler
 ---> Running in 7b56162c0d52
Removing intermediate container 7b56162c0d52
 ---> 5da12ce83939
Step 6/9 : FROM gcr.io/google.com/cloudsdktool/cloud-sdk:alpine AS final
alpine: Pulling from google.com/cloudsdktool/cloud-sdk
05e7bc50f07f: Pull complete
902938da4d80: Pull complete
29db5ebd53be: Pull complete
6f7f9abaa587: Pull complete
Digest: sha256:03606d407f0e5f0cbcea9a2d7c25e10d5214cc6f3f919ee60620a07a9355a773
Status: Downloaded newer image for gcr.io/google.com/cloudsdktool/cloud-sdk:alpine
 ---> e65e2e589d28
Step 7/9 : WORKDIR /
 ---> Running in 89eb2ba31010
Removing intermediate container 89eb2ba31010
 ---> 481743d503a9
Step 8/9 : COPY --from=builder /build/scheduler .
 ---> 90a9fac3c88f
Step 9/9 : CMD [ "./scheduler" ]
 ---> Running in b1f3d5386b8b
Removing intermediate container b1f3d5386b8b
 ---> 17529eb0ad8a
Successfully built 17529eb0ad8a
Successfully tagged europe-west1-docker.pkg.dev/pojala-gcp-playground/gcp-scheduler-repo/gcp_instance_scheduler:latest
```

And finally, push the image to the GCP Repository:

```bash
$ docker push europe-west1-docker.pkg.dev/pojala-gcp-playground/gcp-scheduler-repo/gcp_instance_scheduler
Using default tag: latest
The push refers to repository [europe-west1-docker.pkg.dev/pojala-gcp-playground/gcp-scheduler-repo/gcp_instance_scheduler]
05667cf60bf0: Pushed
a51bd180acb8: Pushed
6c59e8ce38f7: Pushed
392d733a90ad: Pushed
f4666769fca7: Pushed
latest: digest: sha256:9a6af5acf827fd23a622b71748937f90c1e026d8036035035386077ecf15f3bd size: 1371
```

## Terraform templates for Cloud Scheduler and Cloud Run

The example Terraform templates deploy the scheduler into Cloud Run with a Cloud Scheduler to trigger the container every 15 minutes through a Pub/Sub topic.

## Configuration

The container require two mandatory environment variables, `scheduler_projects` and `scheduler_zones`.

`scheduler_projects` is a comma-separated list of GCP projects to check instances.  When you deploy the scheduler, make sure that the container has required access to these projects.

`shceduler_zones` is a comma-separated list of prefixes for GCP Regions.  For example if you want to check through all regions in the US, one could use `us`.  For a more specific
region one could define just `europe-west` or `europe-west1`.  If you deploy instances only to a single region, it is recommended to list it precisely.

Two optional environment variables are available, `scheduler_start_label` and `scheduler_end_label` that define the VM instance label to search for.  By default these are `schedule_start` and `schedule_end`.

Optional environment variable `debug` can be set to enable more verbose logging.

## Instance labels

`schedule_start` and `schedule_end` labels on the VM instance define the start and stop schedule for the instance.  As the label values do not support the required character set
for cron definition, the label value is a `_` (underscore) separate list of time and date values.

`HHMM` defines a specific hour:minute, e.g. `0830` defines 08:30 in the morning and `2145` defined 21:45 in the evening.  
`HH` defines a specific start of hour, e.g. `06` defines 06:00.

`monfri` or `workday` defines weekdays from Monday to Friday (1-5).  
`satsun` or `weekend` defines weekend, Saturday and Sunday (0,6).

`dayNN` defines NN day of the month.  
`hourNN` defines hour of the day.  
`minNN` defines NN min of the month.

`mon`, `tue`, `wed`, `thu`, `fri`, `sat` and `sun` can be used to define a specific day of the week.  
`jan`, `feb`, `mar`, `apr`, `may`, `jun`, `jul`, `aug`, `sep`, `oct`, `nov` and `dec` can be used to define a specific month of the year.

### Examples

`0800_day1_jan_apr_jul_oct` would define `0 8 1 1,4,7,10 *` to run the schedule beginning of each quarter.

`06_workday` would define `0 6 * * 1-5` to run the schedule at 6:00 am every working day (Monday to Friday).

For example to schedule an instance to run between 06:30 and 18:00 every working day, one would define `0630_workday` as the start schedule and `1800_workday` or `18_workday` as the stop schedule.

If you are not familiar with cron scheduler syntax, please see https://en.wikipedia.org/wiki/Cron

## Code

## Example

