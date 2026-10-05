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

setup_suite() {
  export FPM_CONTAINER_NAME="test-fpm-$(unused_port)"
}

teardown_suite() {
  docker stop "${FPM_CONTAINER_NAME}" > /dev/null 2>&1
}
