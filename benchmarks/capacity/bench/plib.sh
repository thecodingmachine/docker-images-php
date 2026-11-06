# Page benchmark: start a configuration on one CPU (2 GB) and load it with k6 at a fixed page rate.
P=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
APP=$P/app
RUN=$P/run
IMAGE_TAG=${IMAGE_TAG:-8.4-v5}

# start <name> <config dir> <cpu>  -> prints the base URL
# The config dir holds: kind (apache | fpm-apache | nginx-fpm), and optionally env, mpm.conf, apache.conf, nginx.conf
start() {
  local name=$1 cfg=$2 cpu=$3 dir=$RUN/$1 kind; kind=$(cat "$cfg/kind")
  stop "$name"; mkdir -p "$dir/visits"
  local image=apache extra=(); [ "$kind" != apache ] && image=fpm
  [ "$kind" = fpm-apache ] && extra+=(-e PHP_FPM_WEB_SERVER=apache)
  local mpm=prefork; [ "$kind" = fpm-apache ] && mpm=event
  [ -f "$cfg/mpm.conf" ] && extra+=(-v "$cfg/mpm.conf:/etc/apache2/mods-available/mpm_$mpm.conf:ro")
  [ -f "$cfg/apache.conf" ] && extra+=(-v "$cfg/apache.conf:/etc/apache2/conf-enabled/zz-tuning.conf:ro")
  [ -f "$cfg/env" ] && extra+=(--env-file "$cfg/env")
  [ -n "${SCENARIO_ENV:-}" ] && extra+=(--env-file "$SCENARIO_ENV")
  docker run -d --name "pb-$name" --cpuset-cpus="$cpu" --memory=2g --memory-swap=2g --ulimit nofile=65535 \
    --env-file "$APP/docker.env" -e PAGE_ITEMS=100 "${extra[@]}" \
    -v "$APP:/var/www/html:ro" -v "$RUN/certs:/certs:ro" -v "$dir/visits:/data" "${REPO:-thecodingmachine/php}:$IMAGE_TAG-$image" >/dev/null
  local ip; ip=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "pb-$name")
  local url=http://$ip
  if [ "$kind" = nginx-fpm ]; then
    docker run -d --name "pb-$name-nginx" --network "container:pb-$name" --cpuset-cpus="$cpu" --ulimit nofile=65535 \
      -v "$cfg/nginx.conf:/etc/nginx/nginx.conf:ro" -v "$RUN/certs:/certs:ro" -v "$APP:/var/www/html:ro" nginx:1.28 >/dev/null
  fi
  for _ in $(seq 60); do curl -sf "$url/health" >/dev/null && break; sleep 0.5; done
  curl -sf "$url/health" >/dev/null || { echo "unhealthy $name" >&2; docker logs --tail 20 "pb-$name" >&2; return 1; }
  [ -f "$cfg/tls" ] && url=https://$ip
  if [ -n "${PROXY_CPU:-}" ]; then
    printf 'http:\n  routers:\n    r: {rule: "PathPrefix(`/`)", service: s, entryPoints: [web]}\n  services:\n    s: {loadBalancer: {servers: [{url: "%s"}]}}\n' "$url" > "$dir/traefik.yml"
    docker run -d --name "pb-$name-proxy" --cpuset-cpus="$PROXY_CPU" --memory=1g --ulimit nofile=65535 \
      -v "$dir/traefik.yml:/dyn.yml:ro" traefik:v3.7 --entrypoints.web.address=:80 --providers.file.filename=/dyn.yml --log.level=ERROR >/dev/null
    url=http://$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "pb-$name-proxy")
    for _ in $(seq 40); do curl -sf "$url/health" >/dev/null && break; sleep 0.25; done
  fi
  curl -skf -o /dev/null "$url/" && curl -skf -o /dev/null "$url/assets/asset1.css" || { echo "page or asset failing on $name" >&2; return 1; }
  echo "$url"
}

stop() { docker rm -f "pb-$1" "pb-$1-nginx" "pb-$1-proxy" $(docker ps -aq --filter "name=^pb-$1-net") >/dev/null 2>&1 || true; rm -rf "$RUN/$1/visits"; }

mem_guard() {
  local avail; avail=$(awk '/MemAvailable/ {print int($2/1024)}' /proc/meminfo)
  [ "$avail" -ge 6144 ] || { echo "mem_guard: only ${avail} MB available" >&2; return 1; }
}

# load <name> <url> <k6 cpus> <rate> <label> -> exit code of k6 (0 = pass)
# Samples the server CPU every second (sum of its containers) and its memory.
load() {
  local name=$1 url=$2 cpus=$3 rate=$4 label=$5 out=$RUN/$1/results
  mkdir -p "$out"; mem_guard || return 3
  local ctrs=("pb-$name"); docker inspect "pb-$name-nginx" >/dev/null 2>&1 && ctrs+=("pb-$name-nginx")
  local proxy=; docker inspect "pb-$name-proxy" >/dev/null 2>&1 && proxy=pb-$name-proxy
  ( while true; do docker stats --no-stream --format '{{.Name}} {{.CPUPerc}} {{.MemUsage}}' "${ctrs[@]}" $proxy 2>/dev/null \
      | awk '{c=$2; gsub("%","",c)} $1 ~ /-proxy$/ {p=c; next} {t+=c} NR==1 {mem=$3} END {print t, mem, p+0}'; done > "$out/$label-stats.log" ) &
  local mon=$! rc=0
  if [ -z "${MIX:-}" ]; then
    k6run "$cpus" "$out" "$url" "$rate" "$label" "" || rc=$?
  else
    # MIX="name:rtt_ms:weight ...": one k6 per client profile, its network delayed by netem
    local pids=() prof n rtt w
    for prof in $MIX; do
      IFS=: read -r n rtt w <<< "$prof"
      docker run -d --name "pb-$name-net-$n" --cpuset-cpus="$cpus" --cap-add NET_ADMIN bench-netem \
        sh -c "tc qdisc add dev eth0 root netem delay ${rtt}ms limit 100000 && exec sleep infinity" >/dev/null
      k6run "$cpus" "$out" "$url" "$(echo "$rate * $w / 100" | bc -l)" "$label-$n" "container:pb-$name-net-$n" & pids+=($!)
    done
    for p in "${pids[@]}"; do wait "$p" || rc=1; done
    docker rm -f $(docker ps -aq --filter "name=^pb-$name-net") >/dev/null 2>&1
  fi
  kill $mon 2>/dev/null; wait $mon 2>/dev/null
  return $rc
}

# k6run <cpus> <out dir> <url> <rate> <label> <network>
k6run() {
  local net=(); [ -n "$6" ] && net=(--network "$6")
  docker run --rm --memory=3g --memory-swap=3g --cpuset-cpus="$1" --ulimit nofile=65535 -u "$(id -u)" "${net[@]}" \
    -v "$P/bench:/b:ro" -v "$2:/out" grafana/k6:1.3.0 run -q --no-color \
    -e BASE_URL="$3" -e RATE="$4" -e RAMP="${RAMP:-10s}" -e DURATION="${HOLD:-30s}" \
    -e P95="${P95:-500}" -e P99="${P99:-1000}" -e THINK="${THINK:-1}" \
    --summary-export "/out/$5.json" /b/page.js > "$2/$5.log" 2>&1
}

# summary <name> <label>: page p95/p99, errors, dropped pages, server CPU (median and p90 over the hold) and max memory
summary() {
  local f=$RUN/$1/results/$2 j
  if [ ! -f "$f.json" ]; then
    for j in "$f"-*.json; do jq -r --arg n "$(basename "$j" .json | sed "s/^$2-//")" '"\($n): p95=\(.metrics["group_duration{group:::page}"]["p(95)"]|floor) p99=\(.metrics["group_duration{group:::page}"]["p(99)"]|floor) fail=\(.metrics.http_req_failed.value*10000|floor/100)% drop=\(.metrics.dropped_iterations.count // 0)"' "$j" | tr '\n' ' '; done
    awk 'NR>5 {print $3}' "$f-stats.log" | head -n -2 | sort -n | awk '{a[NR]=$1} END {if (NR) printf "proxy_cpu_med=%d%% ", a[int((NR+1)/2)]}'
  fi
  jq -r '"p95=\(.metrics["group_duration{group:::page}"]["p(95)"]|floor)ms p99=\(.metrics["group_duration{group:::page}"]["p(99)"]|floor)ms fail=\(.metrics.http_req_failed.value*10000|floor/100)% dropped=\(.metrics.dropped_iterations.count // 0) pages/s=\(.metrics.iterations.rate*100|floor/100)"' "$f.json" 2>/dev/null | tr '\n' ' '
  awk 'NR>5 {print $1}' "$f-stats.log" | head -n -2 | sort -n | awk '{a[NR]=$1} END {if (NR) printf "cpu_med=%d%% cpu_p90=%d%% ", a[int((NR+1)/2)], a[int(NR*0.9)]}'
  awk '{print $2}' "$f-stats.log" | sed 's/MiB//;s/GiB/*1024/' | bc 2>/dev/null | sort -n | tail -1 | awk '{printf "mem_max=%dMiB\n", $1}'
}
