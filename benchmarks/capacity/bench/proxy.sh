# Proxy scenario: Traefik in front, European client mix, 30 ms of I/O and 16 MB per page
export SCENARIO_ENV=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/proxy${PAGE_MEM_MB:-16}.env
export MIX="fiber:15:50 cable:30:30 mobile:50:20"
export HOLD=${HOLD:-60s} THINK=${THINK:-5}
export P95=1000 P99=2000
