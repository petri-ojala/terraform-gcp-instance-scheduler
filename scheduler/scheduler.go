package main

import (
	"context"
	"fmt"
	"log"
	"net/http"
	"os"
	"regexp"
	"strconv"
	"strings"
	"time"

	"github.com/robfig/cron"
	compute "google.golang.org/api/compute/v1"
)

func main() {
	log.Print("starting server...")
	http.HandleFunc("/", handler)

	// Determine port for HTTP service.
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
		log.Printf("defaulting to port %s", port)
	}

	// Start HTTP server.
	log.Printf("listening on port %s", port)
	if err := http.ListenAndServe(":"+port, nil); err != nil {
		log.Fatal(err)
	}
}

func handler(w http.ResponseWriter, r *http.Request) {
	projectList := os.Getenv("scheduler_projects")
	zonePrefixList := os.Getenv("scheduler_zones")

	if projectList == "" || zonePrefixList == "" {
		fmt.Printf("Define scheduler_projects and scheduler_zones environment variables")
		os.Exit(1)
	}

	startLabel := os.Getenv("scheduler_start_label")
	if startLabel == "" {
		startLabel = "schedule_start"
	}
	endLabel := os.Getenv("scheduler_end_label")
	if endLabel == "" {
		endLabel = "schedule_end"
	}

	ctx := context.Background()
	service, err := compute.NewService(ctx)
	if err != nil {
		log.Fatal(err)
	}

	for _, projectId := range strings.Split(projectList, ",") {
		fmt.Printf("Project: %s\n", projectId)
		allZones, err := service.Zones.List(projectId).Do()
		if err != nil {
			log.Fatal(err)
		}

		currentTime := time.Now().Local()
		fmt.Printf("Current: %v (%s)\n", currentTime, currentTime.Location().String())

		for _, zone := range allZones.Items {
			for _, zonePrefix := range strings.Split(zonePrefixList, ",") {
				if strings.HasPrefix(zone.Name, zonePrefix) {
					//fmt.Printf("  %+v\n", zone.Name)
					i, _ := service.Instances.List(projectId, zone.Name).Do()
					startTime := time.Now()
					stopTime := time.Now()
					for _, p := range i.Items {
						fmt.Printf("  %s %s %+v\n", zone.Name, p.Description, p.Labels)
						if val, ok := p.Labels[startLabel]; ok {
							s := parseSchedule(val)
							fmt.Printf("crontab: %s\n", s)
							c := cron.NewParser(cron.Minute | cron.Hour | cron.Dom | cron.Month | cron.Dow)
							startSchedule, err := c.Parse("TZ=" + currentTime.Location().String() + " " + s)
							if err != nil {
								log.Fatal(err)
							}
							fmt.Printf("%v\n", startSchedule.Next(time.Now().Local()))
							startTime = startSchedule.Next(time.Now()).Local()
						}
						if val, ok := p.Labels[endLabel]; ok {
							s := parseSchedule(val)
							fmt.Printf("crontab: %s\n", s)
							c := cron.NewParser(cron.Minute | cron.Hour | cron.Dom | cron.Month | cron.Dow)
							stopSchedule, err := c.Parse("TZ=" + currentTime.Location().String() + " " + s)
							if err != nil {
								log.Fatal(err)
							}
							fmt.Printf("%v\n", stopSchedule.Next(time.Now().Local()))
							stopTime = stopSchedule.Next(time.Now()).Local()
						}
						if startTime != stopTime {
							if startTime.After(stopTime) && currentTime.Before(stopTime) && p.Status != "RUNNING" {
								s, err := service.Instances.Start(projectId, zone.Name, strconv.FormatUint(p.Id, 10)).Do()
								fmt.Printf("    START %+v %+v\nn", s, err)
							}
							if stopTime.After(startTime) && currentTime.Before(startTime) && p.Status == "RUNNING" {
								s, err := service.Instances.Stop(projectId, zone.Name, strconv.FormatUint(p.Id, 10)).Do()
								fmt.Printf("    STOP %+v %+v\nn", s, err)
							}
						}
					}
				}
			}
		}
	}
}

func parseSchedule(i string) string {
	cronMin := []string{}
	cronHour := []string{}
	cronDay := []string{}
	cronMonth := []string{}
	cronWeekday := []string{}

	checkHHMM := regexp.MustCompile(`^[0-9][0-9][0-9][0-9]$`)
	checkHH := regexp.MustCompile(`^[0-9][0-9]$`)

	for _, v := range strings.Split(i, "_") {
		if checkHHMM.MatchString(v) {
			// HHMM
			cronHour = append(cronHour, v[:2])
			cronMin = append(cronMin, v[len(v)-2:])
			continue
		}
		if checkHH.MatchString(v) {
			// HH00
			cronHour = append(cronHour, v)
			cronMin = append(cronMin, "0")
			continue
		}
		if strings.HasPrefix(v, "day") {
			cronDay = append(cronDay, strings.TrimPrefix(v, "day"))
			continue
		}
		if strings.HasPrefix(v, "hour") {
			cronHour = append(cronHour, strings.TrimPrefix(v, "hour"))
			continue
		}
		if strings.HasPrefix(v, "min") {
			cronMin = append(cronMin, strings.TrimPrefix(v, "min"))
			continue
		}
		if v == "monfri" || v == "wrk" || v == "workday" {
			cronWeekday = append(cronWeekday, "1-5")
			continue
		}
		if v == "satsun" || v == "nowrk" || v == "wknd" || v == "weekend" {
			cronWeekday = append(cronWeekday, "0,6")
			continue
		}

		matchDay := strings.Index("sunmontuewedthufrisat", v)
		if matchDay%3 == 0 {
			cronWeekday = append(cronWeekday, strconv.Itoa(matchDay/3))
			continue
		}

		matchMonth := strings.Index("janfebmaraprmayjunjulaugsepoctnovdev", v)
		if matchMonth%3 == 0 {
			cronMonth = append(cronMonth, strconv.Itoa(1+matchMonth/3))
			continue
		}

	}
	if len(cronDay) == 0 {
		cronDay = []string{"*"}
	}
	if len(cronWeekday) == 0 {
		cronWeekday = []string{"*"}
	}
	if len(cronMonth) == 0 {
		cronMonth = []string{"*"}
	}
	if len(cronMin) == 0 {
		cronMin = []string{"0"}
	}
	if len(cronHour) == 0 {
		cronHour = []string{"*"}
	}
	return fmt.Sprintf("%s %s %s %s %s", strings.Join(cronMin, ","), strings.Join(cronHour, ","), strings.Join(cronDay, ","), strings.Join(cronMonth, ","), strings.Join(cronWeekday, ","))
}
