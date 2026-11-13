#!/usr/bin/env bash
# Runs the saturation search of several configurations one after the other on the same CPUs.
#   lane.sh <cpu> <k6 cpus> <config>...
cpu=$1 k6=$2; shift 2
for c in "$@"; do bash "$(dirname "$0")/search.sh" "$c" "$(dirname "$0")/../configs/$c" "$cpu" "$k6"; done
