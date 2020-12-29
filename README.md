# GCP Instance Scheduler

Simple instance scheduler for Google Cloud that can be used in any container platform (e.g. Cloud Run or GKE), can be scheduled to run by e.g. Cloud Scheduler or Kubernetes CronJob, and instance schedules can be controlled by instance labels with crontab-like capabilities.

![Scheduler workflow](scheduler.png)

## Create the container image

...

## Terraform templates for Cloud Scheduler and Cloud Run

The example Terraform templates deploy the scheduler into Cloud Run with a Cloud Scheduler to trigger the container every 15 minutes through a Pub/Sub topic.

## Configuration

The container require two mandatory environment variables, `scheduler_projects` and `scheduler_zones`.

`scheduler_projects` is a comma-separated list of GCP projects to check instances.  When you deploy the scheduler, make sure that the container has required access to these projects.

`shceduler_zones` is a comma-separated list of prefixes for GCP Regions.  For example if you want to check through all regions in the US, one could use `us`.  For a more specific
region one could define just `europe-west` or `europe-west1`.  If you deploy instances only to a single region, it is recommended to list it precisely.

Two optional environment variables are available, `scheduler_start_label` and `scheduler_end_label` that define the VM instance label to search for.  By default these are `schedule_start` and `schedule_end`.

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

