#!/bin/bash
# Usage: supervise.sh <commands file> <image stop signal> <main command stop signal> <main command...>
#
# Runs the main command along with the commands of the file: pairs of a name and a command, separated by NUL characters.
# As soon as one of these processes exits, or SIGTERM, SIGINT or the image stop signal is received, the others are
# stopped (the main command with its stop signal, the others with SIGTERM). The script exits with the exit code of
# the first process that exited.
# When the stop is requested by a signal, the script exits with the exit code of the main command.

COMMANDS_FILE=$1
IMAGE_STOP_SIGNAL=$2
STOP_SIGNAL=$3
shift 3

declare -A NAMES
MAIN_PID=
MAIN_EXIT_CODE=
STOPPING=
STOP_REQUESTED=

stop() {
    STOPPING=$1
    [[ -n "$MAIN_PID" ]] && kill -"$1" "$MAIN_PID" 2> /dev/null
    for PID in "${!NAMES[@]}"; do
        kill -TERM "$PID" 2> /dev/null
    done
}

for SIGNAL in HUP USR1 USR2 QUIT WINCH; do
    trap "[[ -n \"\$MAIN_PID\" ]] && kill -$SIGNAL \"\$MAIN_PID\" 2> /dev/null" "$SIGNAL"
done
trap 'STOP_REQUESTED=1; stop TERM' TERM
trap 'STOP_REQUESTED=1; stop INT' INT
if [[ "$IMAGE_STOP_SIGNAL" != TERM ]]; then
    trap 'STOP_REQUESTED=1; stop "$STOP_SIGNAL"' "$IMAGE_STOP_SIGNAL"
fi

while IFS= read -r -d '' NAME && IFS= read -r -d '' COMMAND; do
    bash -c "$COMMAND" &
    NAMES[$!]=$NAME
done < "$COMMANDS_FILE"
"$@" <&0 &
MAIN_PID=$!

# A stop requested while the processes were starting
[[ -n "$STOPPING" ]] && stop "$STOPPING"

# Checks every second which processes exited (wait -n can miss a process already reaped by bash)
while [[ -z "$MAIN_EXIT_CODE" ]] || (( ${#NAMES[@]} > 0 )); do
    sleep 1 &
    wait $!

    RUNNING_PIDS=("${!NAMES[@]}")
    [[ -z "$MAIN_EXIT_CODE" ]] && RUNNING_PIDS+=("$MAIN_PID")
    for PID in "${RUNNING_PIDS[@]}"; do
        kill -0 "$PID" 2> /dev/null && continue
        wait "$PID"
        CODE=$?

        if [[ "$PID" == "$MAIN_PID" ]]; then
            MAIN_EXIT_CODE=$CODE
        else
            EXITED_NAME=${NAMES[$PID]}
            unset "NAMES[$PID]"
        fi
        if [[ -z "$STOPPING" ]]; then
            EXIT_CODE=$CODE
            if [[ "$PID" != "$MAIN_PID" ]]; then
                echo "$EXITED_NAME exited with code $CODE: stopping the container" >&2
            fi
            stop "$STOP_SIGNAL"
        fi
    done
done

if [[ -n "$STOP_REQUESTED" ]]; then
    exit "$MAIN_EXIT_CODE"
fi
exit "$EXIT_CODE"
