#!/usr/bin/env bash
# Compares the "apache" variant (mod_php, mpm_prefork) and the "fpm" variant with its built-in Apache
# (PHP_FPM_WEB_SERVER=apache: mpm_event + PHP-FPM), labelled "fpm-apache".
#
# Both variants receive exactly the same load: a constant number of pages per second (open model),
# for several rates. The capacity of a variant is the highest rate served with a page p95 under
# MAX_P95 ms and a p99 under MAX_P99 ms (no request stuck), without error nor dropped page.
#
# Usage: ./run.sh [php version]
# Env: RATES, PHP_RATES, DURATION, MAX_P95, MAX_P99, CPUS, MEMORY, FPM_MAX_CHILDREN, REPO, TAG_PREFIX,
#      SUMMARY_ONLY=1 (only print the summary of the previous run)
set -e
cd "$(dirname "$0")"

PHP_VERSION="${1:-8.4}"
REPO="${REPO:-thecodingmachine/php}"
TAG_PREFIX="${TAG_PREFIX:-}"
RATES="${RATES:-10 15 20 30 40 60 80}"
PHP_RATES="${PHP_RATES:-100 200 300}"
DURATION="${DURATION:-30s}"
MAX_P95="${MAX_P95:-100}"
MAX_P99="${MAX_P99:-1000}"
CPUS="${CPUS:-2}"
MEMORY="${MEMORY:-2g}"
FPM_MAX_CHILDREN="${FPM_MAX_CHILDREN:-20}"
NETWORK="bench-fpm-apache"
RESULTS="results"
VARIANTS="apache fpm-apache"

if [[ "$SUMMARY_ONLY" != "1" ]]; then
mkdir -p "$RESULTS" app/assets
for i in $(seq 1 10); do
    [[ -f "app/assets/asset$i.css" ]] || head -c 30000 /dev/urandom | base64 > "app/assets/asset$i.css"
done
docker network create "$NETWORK" > /dev/null 2>&1 || true

k6() {
    docker run --rm -u "$(id -u)" --network "$NETWORK" -v "$PWD":/bench grafana/k6 run -q "$@" /bench/scenario.js
}

# run_level <variant> <container> <name of the result> <k6 options...>
run_level() {
    local variant="$1" container="$2" result="$3"; shift 3
    # Sample memory and CPU of the server during the run
    (while true; do
        docker stats --no-stream --format '{{.MemUsage}};{{.CPUPerc}}' "$container" 2>/dev/null || break
     done) > "$RESULTS/${variant}-${result}-stats.log" &
    local stats_pid=$!
    k6 -e DURATION="$DURATION" "$@" \
        --summary-export "/bench/$RESULTS/${variant}-${result}-summary.json" > "$RESULTS/${variant}-${result}-k6.log" 2>&1 || true
    kill "$stats_pid" 2>/dev/null || true
    wait "$stats_pid" 2>/dev/null || true
    # Let idle connections and processes settle between levels
    sleep 10
}

bench() {
    local variant="$1"; local image_variant="$2"; shift 2
    local name="bench-${variant}"
    docker rm -f "$name" > /dev/null 2>&1 || true
    docker run -d --name "$name" --network "$NETWORK" --network-alias app \
        --cpus "$CPUS" --memory "$MEMORY" \
        -e TEMPLATE_PHP_INI=production "$@" \
        -v "$PWD/app":/var/www/html:ro \
        "${REPO}:${TAG_PREFIX}${PHP_VERSION}-v5-slim-${image_variant}" > /dev/null
    sleep 5
    # Warm up (opcache, process spawning)
    k6 -e RATE=5 -e DURATION=10s > /dev/null 2>&1
    for rate in $RATES; do
        run_level "$variant" "$name" "page-${rate}" -e RATE="$rate"
    done
    for rate in $PHP_RATES; do
        run_level "$variant" "$name" "php-${rate}" -e RATE="$rate" -e PHP_ONLY=1
    done
    docker logs "$name" > "$RESULTS/${variant}-server.log" 2>&1
    docker rm -f "$name" > /dev/null
}

bench apache apache
bench fpm-apache fpm -e PHP_FPM_WEB_SERVER=apache -e PHP_FPM_PM=static -e PHP_FPM_PM_MAX_CHILDREN="$FPM_MAX_CHILDREN"
docker network rm "$NETWORK" > /dev/null
fi

# |-- Summary ----------------------------------------------------------------
# metrics <summary.json>: p50, p95, p99, max, errors (%), dropped
metrics() {
    jq -r '[
        (.metrics["group_duration{group:::page}"]["p(50)"] | floor),
        (.metrics["group_duration{group:::page}"]["p(95)"] | floor),
        (.metrics["group_duration{group:::page}"]["p(99)"] | floor),
        (.metrics["group_duration{group:::page}"].max | floor),
        (.metrics.http_req_failed.value * 1000 | floor / 10),
        (.metrics.dropped_iterations.count // 0)
      ] | map(tostring) | join(" ")' "$1"
}
max_mib() {
    cut -d';' -f1 "$1" | cut -d'/' -f1 | sed 's/ //g' | awk '
      /GiB$/ {v=$0; sub(/GiB/,"",v); v*=1024}
      /MiB$/ {v=$0; sub(/MiB/,"",v)}
      /KiB$/ {v=$0; sub(/KiB/,"",v); v/=1024}
      {if (v>m) m=v} END {printf "%d", m}'
}
avg_cpu() {
    cut -d';' -f2 "$1" | tr -d '%' | awk '$1>1 {s+=$1; n++} END {printf "%d", (n ? s/n : 0)}'
}
# table <kind> <rates> <label of the rate>
table() {
    local kind="$1" rates="$2" label="$3"
    echo "| ${label} | Variant | p50 (ms) | p95 (ms) | p99 (ms) | Max (ms) | Errors (%) | Dropped | Peak memory (MiB) | Avg CPU (%) | OK |"
    echo "|---|---|---|---|---|---|---|---|---|---|---|"
    for rate in $rates; do
        for v in $VARIANTS; do
            read -r p50 p95 p99 max errors dropped <<< "$(metrics "$RESULTS/${v}-${kind}-${rate}-summary.json")"
            local ok="❌"
            if within_limits "$p95" "$p99" "$errors" "$dropped"; then ok="✅"; fi
            echo "| ${rate} | ${v} | ${p50} | ${p95} | ${p99} | ${max} | ${errors} | ${dropped} | $(max_mib "$RESULTS/${v}-${kind}-${rate}-stats.log") | $(avg_cpu "$RESULTS/${v}-${kind}-${rate}-stats.log") | ${ok} |"
        done
    done
}
# within_limits <p95> <p99> <errors> <dropped>
within_limits() {
    [[ "$1" -lt "$MAX_P95" ]] && [[ "$2" -lt "$MAX_P99" ]] && [[ "$3" == "0" ]] && [[ "$4" == "0" ]]
}
# capacity <kind> <rates> <variant>: highest rate within the limits (and all the lower rates within them too)
capacity() {
    local kind="$1" rates="$2" v="$3"
    local best="< ${rates%% *}"
    for rate in $rates; do
        read -r p50 p95 p99 max errors dropped <<< "$(metrics "$RESULTS/${v}-${kind}-${rate}-summary.json")"
        within_limits "$p95" "$p99" "$errors" "$dropped" || break
        best="$rate"
    done
    echo "$best"
}

{
    echo "OK: p95 < ${MAX_P95} ms, p99 < ${MAX_P99} ms, no error and no dropped request"
    echo
    echo "PHP ${PHP_VERSION} - ${DURATION} per rate - server limited to ${CPUS} CPUs / ${MEMORY} - PHP-FPM: ${FPM_MAX_CHILDREN} workers (static)"
    echo
    echo "### Browsing: same number of pages per second for both variants"
    echo
    table page "$RATES" "Pages/s"
    echo
    echo "### PHP only: same number of PHP requests per second for both variants"
    echo
    table php "$PHP_RATES" "Requests/s"
    echo
    echo "### Capacity (highest rate with p95 < ${MAX_P95} ms and p99 < ${MAX_P99} ms, no error, no dropped request)"
    echo
    echo "| Variant | Browsing (pages/s) | PHP only (requests/s) |"
    echo "|---|---|---|"
    for v in $VARIANTS; do
        echo "| ${v} | $(capacity page "$RATES" "$v") | $(capacity php "$PHP_RATES" "$v") |"
    done
} | tee "$RESULTS/summary.md"
