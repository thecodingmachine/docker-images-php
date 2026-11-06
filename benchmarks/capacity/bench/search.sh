#!/usr/bin/env bash
# Saturation search for one configuration, fresh server on every run:
# +STEP pages/s until the first failure, then halve the interval down to PREC.
#   search.sh <name> <config dir> <cpu> <k6 cpus>
set -u
source "$(dirname "$0")/plib.sh"
name=$1 cfg=$2 cpu=$3 k6cpus=$4
STEP=${STEP:-50} PREC=${PREC:-5}
mkdir -p "$RUN/$name"; LOG=$RUN/$name/search.log
echo $$ > "$RUN/$name/pid"
say() { echo "$(date +%T) $name $*" | tee -a "$LOG"; }
run() {
  local url; url=$(start "$name" "$cfg" "$cpu") || { say "rate=$1 START FAILED"; return 2; }
  load "$name" "$url" "$k6cpus" "$1" "r$1"; local rc=$?
  say "rate=$1 rc=$rc $(summary "$name" "r$1")"
  stop "$name"; sleep 3
  return $rc
}
lo=${LO:-0}
if [ -n "${HI:-}" ]; then hi=$HI; else
  v=${START:-$STEP}
  while run $v; do lo=$v; v=$((v + STEP)); done
  hi=$v
fi
while [ $((hi - lo)) -gt "$PREC" ]; do
  mid=$(( (lo + hi) / 2 ))
  if run $mid; then lo=$mid; else hi=$mid; fi
done
say "LIMIT between $lo (pass) and $hi (fail) pages/s"
rm -f "$RUN/$name/pid"
