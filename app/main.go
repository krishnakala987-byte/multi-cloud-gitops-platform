// cloud-atlas: a tiny cloud-aware service used to demonstrate multi-cloud
// GitOps delivery. It reports WHICH cloud/cluster/region is serving traffic,
// exposes /healthz for load-balancer + DNS health checks, and /metrics in
// Prometheus text exposition format (stdlib only - zero dependencies).
package main


import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"sync/atomic"
	"time"
)

var (
	startTime = time.Now()
	requests  uint64
	healthy   int32 = 1
)

func getenv(key, fallback string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return fallback
}

type info struct {
	Service   string `json:"service"`
	Version   string `json:"version"`
	Cloud     string `json:"cloud"`
	Cluster   string `json:"cluster"`
	Region    string `json:"region"`
	Pod       string `json:"pod"`
	Node      string `json:"node"`
	UptimeSec int64  `json:"uptime_seconds"`
	Time      string `json:"time_utc"`
}

func main() {
	cloud := getenv("CLOUD_PROVIDER", "unknown")
	cluster := getenv("CLUSTER_NAME", "unknown")
	region := getenv("CLOUD_REGION", "unknown")
	version := getenv("APP_VERSION", "dev")
	port := getenv("PORT", "8080")

	mux := http.NewServeMux()

	mux.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		if r.URL.Path != "/" {
			http.NotFound(w, r)
			return
		}
		atomic.AddUint64(&requests, 1)
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(info{
			Service:   "cloud-atlas",
			Version:   version,
			Cloud:     cloud,
			Cluster:   cluster,
			Region:    region,
			Pod:       getenv("POD_NAME", "unknown"),
			Node:      getenv("NODE_NAME", "unknown"),
			UptimeSec: int64(time.Since(startTime).Seconds()),
			Time:      time.Now().UTC().Format(time.RFC3339),
		})
	})

	// Used by: kubelet liveness/readiness probes, cloud LB health probes,
	// and Route 53 health checks driving cross-cloud DNS failover.
	mux.HandleFunc("/healthz", func(w http.ResponseWriter, r *http.Request) {
		if atomic.LoadInt32(&healthy) == 1 {
			w.WriteHeader(http.StatusOK)
			fmt.Fprintln(w, "ok")
			return
		}
		w.WriteHeader(http.StatusServiceUnavailable)
	})

	// Flip health to simulate a failing region during failover drills:
	//   curl -X POST http://<lb>/chaos/unhealthy   (restore: /chaos/healthy)
	mux.HandleFunc("/chaos/unhealthy", func(w http.ResponseWriter, r *http.Request) {
		if r.Method != http.MethodPost {
			w.WriteHeader(http.StatusMethodNotAllowed)
			return
		}
		atomic.StoreInt32(&healthy, 0)
		fmt.Fprintln(w, "healthz will now return 503")
	})
	mux.HandleFunc("/chaos/healthy", func(w http.ResponseWriter, r *http.Request) {
		if r.Method != http.MethodPost {
			w.WriteHeader(http.StatusMethodNotAllowed)
			return
		}
		atomic.StoreInt32(&healthy, 1)
		fmt.Fprintln(w, "healthz restored")
	})

	// Prometheus text exposition format, scraped by kube-prometheus-stack.
	mux.HandleFunc("/metrics", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "text/plain; version=0.0.4")
		fmt.Fprintf(w, "# HELP cloud_atlas_requests_total Requests served.\n")
		fmt.Fprintf(w, "# TYPE cloud_atlas_requests_total counter\n")
		fmt.Fprintf(w, "cloud_atlas_requests_total{cloud=%q,cluster=%q,region=%q} %d\n",
			cloud, cluster, region, atomic.LoadUint64(&requests))
		fmt.Fprintf(w, "# HELP cloud_atlas_up 1 if serving.\n")
		fmt.Fprintf(w, "# TYPE cloud_atlas_up gauge\n")
		fmt.Fprintf(w, "cloud_atlas_up{cloud=%q,cluster=%q} %d\n", cloud, cluster, atomic.LoadInt32(&healthy))
	})

	srv := &http.Server{
		Addr:         ":" + port,
		Handler:      mux,
		ReadTimeout:  5 * time.Second,
		WriteTimeout: 10 * time.Second,
	}
	log.Printf("cloud-atlas %s serving on :%s (cloud=%s cluster=%s region=%s)",
		version, port, cloud, cluster, region)
	log.Fatal(srv.ListenAndServe())
}
