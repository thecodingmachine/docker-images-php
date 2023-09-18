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
  docker run --name test-fpm1 ${RUN_OPTIONS} --rm -e MYVAR=foo -e PHP_INI_MEMORY_LIMIT=2G -p "9001:9000" -d -v "${SCRIPT_DIR}/assets/":/var/www/html \
    "${REPO}:${TAG_PREFIX}${PHP_VERSION}-${BRANCH}-${BRANCH_VARIANT}" > /dev/null
  assert_equals "0" "$?" "Docker run failed"
  # Let's wait for FPM to start
  sleep 3
  # If the container is still up, it will not fail when stopping.
  docker stop test-fpm1 > /dev/null 2>&1
  assert_equals "0" "$?" "Docker stop failed"
}

teardown_suite() {
  docker stop test-fpm1 > /dev/null 2>&1
}
