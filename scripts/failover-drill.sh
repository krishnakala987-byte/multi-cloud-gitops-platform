#!/usr/bin/env bash
# Watch which CLOUD serves your global URL, 1 request/second, with timestamps.
# Run this, then break a cloud in another terminal:
#   kubectl --context aws -n cloud-atlas scale deploy/cloud-atlas --replicas=0
# or the softer version (LB stays, app reports unhealthy):
#   curl -X POST http://aws.app.yourdomain.xyz/chaos/unhealthy
# Watch Route 53 pull it out of rotation. Measure your RTO from the log.
set -euo pipefail
URL="${1:?usage: $0 http://app.yourdomain.xyz/}"

echo "time_utc,cloud,pod" | tee failover-drill.csv
while true; do
  line=$(curl -s --max-time 2 "$URL" | python3 -c \
    'import sys,json;d=json.load(sys.stdin);print(f"{d[\"time_utc\"]},{d[\"cloud\"]},{d[\"pod\"]}")' \
    2>/dev/null || echo "$(date -u +%FT%TZ),UNREACHABLE,-")
  echo "$line" | tee -a failover-drill.csv
  sleep 1
done
