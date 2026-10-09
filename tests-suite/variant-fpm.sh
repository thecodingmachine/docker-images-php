#!/usr/bin/env bash
. ./config

if [[ $VARIANT != fpm* ]]; then
  echo "-- There is not an 'fpm' variant"
  return 0;
fi;
############################################################
## Test if environment starts without errors
############################################################
test_start() {
  docker run --name "${FPM_CONTAINER_NAME}" ${RUN_OPTIONS} --rm -e MYVAR=foo -e PHP_INI_MEMORY_LIMIT=2G -p "$(unused_port):9000" -d -v "${SCRIPT_DIR}/assets/":/var/www/html \
    "${REPO}:${TAG_PREFIX}${PHP_VERSION}-${BRANCH}-slim-${BRANCH_VARIANT}${ARCH_SUFFIX}" > /dev/null
  assert_equals "0" "$?" "Docker run failed"
  # Let's wait for FPM to start
  sleep 3
  # If the container is still up, it will not fail when stopping.
  docker stop "${FPM_CONTAINER_NAME}" > /dev/null 2>&1
  assert_equals "0" "$?" "Docker stop failed"
}

############################################################
## Graceful stop (SIGQUIT): fast and successful exit
############################################################
test_gracefulStop() {
  docker run --name "${FPM_STOP_CONTAINER_NAME}" ${RUN_OPTIONS} -d \
    "${REPO}:${TAG_PREFIX}${PHP_VERSION}-${BRANCH}-slim-${BRANCH_VARIANT}${ARCH_SUFFIX}" > /dev/null
  # Let's wait for FPM to start
  for _ in $(seq 1 60); do
    docker logs "${FPM_STOP_CONTAINER_NAME}" 2>&1 | grep -q "ready to handle connections" && break
    sleep 0.5
  done
  START=$(date +%s)
  docker stop "${FPM_STOP_CONTAINER_NAME}" > /dev/null 2>&1
  DURATION=$(( $(date +%s) - START ))
  EXIT_CODE="$(docker inspect -f '{{.State.ExitCode}}' "${FPM_STOP_CONTAINER_NAME}")"
  docker rm "${FPM_STOP_CONTAINER_NAME}" > /dev/null 2>&1
  assert_equals "0" "$EXIT_CODE" "PHP-FPM did not stop gracefully"
  assert "test ${DURATION} -lt 5" "PHP-FPM took ${DURATION}s to stop (killed by timeout?)"
}
############################################################
## A stop requested during the initialization is not lost
############################################################
test_stopDuringStartup() {
  docker run --name "${FPM_STOP_CONTAINER_NAME}" ${RUN_OPTIONS} -d \
    "${REPO}:${TAG_PREFIX}${PHP_VERSION}-${BRANCH}-slim-${BRANCH_VARIANT}${ARCH_SUFFIX}" > /dev/null
  sleep 0.3
  START=$(date +%s)
  docker stop "${FPM_STOP_CONTAINER_NAME}" > /dev/null 2>&1
  DURATION=$(( $(date +%s) - START ))
  docker rm -f "${FPM_STOP_CONTAINER_NAME}" > /dev/null 2>&1
  assert "test ${DURATION} -lt 5" "Stopping during startup took ${DURATION}s (killed by timeout?)"
}

setup_suite() {
  export FPM_CONTAINER_NAME="test-fpm-$(unused_port)"
  export FPM_STOP_CONTAINER_NAME="test-fpm-stop-$(unused_port)"
}

teardown_suite() {
  docker stop "${FPM_CONTAINER_NAME}" > /dev/null 2>&1
  docker rm -f "${FPM_STOP_CONTAINER_NAME}" > /dev/null 2>&1
}
