#!/usr/bin/env bash
# Traffic spike: RATE pages/s for HOLD on a fresh server, reports what was served and the OOM kills.
#   spike.sh <cpu> <k6 cpus> <rate> <label> <config>...
set -u
source "$(dirname "$0")/plib.sh"
cpu=$1 k6cpus=$2 rate=$3 label=$4; shift 4
for c in "$@"; do
  name=$c; LOG=$RUN/$name/spike.log; mkdir -p "$RUN/$name"
  url=$(start "$name" "$P/configs/$c" "$cpu") || { echo "$(date +%T) $name START FAILED" | tee -a "$LOG"; continue; }
  id=$(docker inspect -f '{{.Id}}' "pb-$name")
  load "$name" "$url" "$k6cpus" "$rate" "$label"
  oom=$(awk '/oom_kill/ {print $2}' "/sys/fs/cgroup/system.slice/docker-$id.scope/memory.events" 2>/dev/null)
  served=$(cat "$RUN/$name/results/$label"-*.json | jq -s '[.[].metrics.iterations.rate] | add | .*10 | floor / 10')
  echo "$(date +%T) $name $label rate=$rate served=${served}pages/s oom_kills=${oom:-?} $(summary "$name" "$label")" | tee -a "$LOG"
  stop "$name"; sleep 3
done
