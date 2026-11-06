#!/usr/bin/env bash
. ./config

IMAGE="${REPO}:${TAG_PREFIX}${PHP_VERSION}-${BRANCH}-slim-${BRANCH_VARIANT}${ARCH_SUFFIX}"

# Waits until the main command of the variant answers and the daemon "sleep 300" runs in the container $1
wait_started() {
  local check
  case "${VARIANT}" in
    apache*) check='curl -s -o /dev/null http://localhost/ && pgrep -x sleep' ;;
    fpm*) check='php-fpm-healthcheck && pgrep -x sleep' ;;
    *) check='test "$(pgrep -cx sleep)" -ge 2' ;;
  esac
  for _ in $(seq 1 60); do
    docker exec "$1" bash -c "${check}" > /dev/null 2>&1 && return 0
    sleep 0.5
  done
  return 1
}

############################################################
## DAEMON_COMMAND runs along with the main command, with the same user
############################################################
test_runWithMainCommand() {
  RESULT="$(docker run ${RUN_OPTIONS} --rm -e DAEMON_COMMAND_1="whoami; sleep 30" "${IMAGE}" sleep 2 2>&1)"
  assert_equals "0" "$?" "The container should exit with the code of the main command"
  assert_equals "docker" "$RESULT"
}
############################################################
## DAEMON_USER runs the daemon with another user
############################################################
test_daemonUser() {
  RESULT="$(docker run ${RUN_OPTIONS} --rm -e DAEMON_COMMAND_1="whoami; sleep 30" -e DAEMON_USER_1="www-data" \
    -e DAEMON_COMMAND_2="id -u; sleep 30" -e DAEMON_USER_2="0" "${IMAGE}" sleep 2 2>&1 | sort | tr '\n' ' ')"
  assert_equals "0 www-data " "$RESULT"
}
############################################################
## The container stops as soon as a daemon exits
############################################################
test_stopWhenDaemonExits() {
  START=$(date +%s)
  RESULT="$(docker run ${RUN_OPTIONS} --rm -e DAEMON_COMMAND_1="sleep 30" -e DAEMON_COMMAND_2="exit 3" "${IMAGE}" sleep 30 2>&1)"
  CODE=$?
  DURATION=$(( $(date +%s) - START ))
  assert_equals "3" "$CODE" "The container should exit with the code of the daemon"
  assert_matches 'DAEMON_COMMAND_2 \(exit 3\) exited with code 3' "$RESULT"
  assert "test ${DURATION} -lt 10" "Stopping took ${DURATION}s"
}
############################################################
## A docker stop stops the main command and the daemons
############################################################
test_dockerStop() {
  if [[ $VARIANT == cli* ]]; then COMMAND="sleep 300"; else COMMAND=""; fi
  docker run --name "${STOP_NAME}" ${RUN_OPTIONS} -d -e DAEMON_COMMAND_1="sleep 300" "${IMAGE}" ${COMMAND} > /dev/null
  wait_started "${STOP_NAME}"
  START=$(date +%s)
  docker stop "${STOP_NAME}" > /dev/null 2>&1
  DURATION=$(( $(date +%s) - START ))
  CODE="$(docker inspect -f '{{.State.ExitCode}}' "${STOP_NAME}")"
  docker rm -f "${STOP_NAME}" > /dev/null 2>&1
  assert "test ${DURATION} -lt 5" "Stopping took ${DURATION}s (killed by timeout?)"
  if [[ $VARIANT != cli* ]]; then
    assert_equals "0" "$CODE" "The graceful stop should exit with 0"
  fi
}

setup_suite() {
  export STOP_NAME="test-daemon-stop-$(unused_port)"
}

teardown_suite() {
  docker rm -f "${STOP_NAME}" > /dev/null 2>&1
}
