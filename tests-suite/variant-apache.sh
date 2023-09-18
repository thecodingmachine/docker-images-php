#!/usr/bin/env bash
. ./config

if [[ $VARIANT != apache* ]]; then
  echo "-- There is not an 'apache' variant"
  return 0;
fi;
############################################################
## Run apache and try to retrieve var content
############################################################
test_displayVarInPhp() {
  RESULT="$(curl -sq http://localhost:${DOCKER1_PORT}/apache/ 2>&1)"
  assert_equals "foo" "$RESULT" "MYVAR was not populate onto php"
}
############################################################
## Run apache with relative document root
############################################################
test_documentRootRelative() {
  RESULT="$(curl -sq http://localhost:${DOCKER2_PORT}/ 2>&1)"
  assert_equals "foo" "$RESULT" "Apache document root (relative) does not work properly"
}
############################################################
## Run apache with absolute document root
############################################################
test_documentRootAbsolute() {
  RESULT="$(curl -sq http://localhost:${DOCKER3_PORT}/ 2>&1)"
  assert_equals "foo" "$RESULT" "Apache document root (absolute) does not work properly"
}
############################################################
## Run apache HtAccess
############################################################
test_htaccessRewrite() {
  RESULT="$(curl -sq http://localhost:${DOCKER1_PORT}/apache/htaccess/ 2>&1)"
  assert_equals "foo" "$RESULT" "Apache HtAccess RewriteRule was not applied"
}
############################################################
## Test PHP_INI_... variables are correctly handled by apache
############################################################
test_changeMemoryLimit() {
  RESULT="$(curl -sq http://localhost:${DOCKER1_PORT}/apache/echo_memory_limit.php 2>&1 )"
  assert_equals "2G" "$RESULT" "Apache PHP_INI_MEMORY_LIMIT was not applied"
}

setup_suite() {
  # SETUP apache1
  export DOCKER1_PORT="$(unused_port)"
  export DOCKER1_NAME="test-apache1-${DOCKER1_PORT}"
  docker run --name "${DOCKER1_NAME}" ${RUN_OPTIONS} --rm -e MYVAR=foo -e PHP_INI_MEMORY_LIMIT=2G -p "${DOCKER1_PORT}:80" -d -v "${SCRIPT_DIR}/assets/":/var/www/html \
    "${REPO}:${TAG_PREFIX}${PHP_VERSION}-${BRANCH}-${BRANCH_VARIANT}" > /dev/null
  assert_equals "0" "$?" "Docker run failed"
  # SETUP apache2
  export DOCKER2_PORT="$(unused_port)"
  export DOCKER2_NAME="test-apache2-${DOCKER2_PORT}"
  docker run --name "${DOCKER2_NAME}" ${RUN_OPTIONS} --rm -e MYVAR=foo -e APACHE_DOCUMENT_ROOT=apache -p "${DOCKER2_PORT}:80" -d -v "${SCRIPT_DIR}/assets/":/var/www/html \
    "${REPO}:${TAG_PREFIX}${PHP_VERSION}-${BRANCH}-${BRANCH_VARIANT}" > /dev/null
  assert_equals "0" "$?" "Docker run failed"
  # SETUP apache3
  export DOCKER3_PORT="$(unused_port)"
  export DOCKER3_NAME="test-apache3-${DOCKER3_PORT}"
  docker run --name "${DOCKER3_NAME}" ${RUN_OPTIONS} --rm -e MYVAR=foo -e APACHE_DOCUMENT_ROOT=/var/www/foo/apache -p "${DOCKER3_PORT}:80" -d -v "${SCRIPT_DIR}/assets/":/var/www/foo  \
    "${REPO}:${TAG_PREFIX}${PHP_VERSION}-${BRANCH}-.scr2
    . 2 ${BRANCH_VARIANT}" > /dev/null
  assert_equals "0" "$?" "Docker run failed"
  # Let's wait for Apache to start
  waitfor http://localhost:${DOCKER1_PORT}
  waitfor http://localhost:${DOCKER2_PORT}
  waitfor http://localhost:${DOCKER3_PORT}
}

teardown_suite() {
  docker stop "${DOCKER1_NAME}" "${DOCKER2_NAME}" "${DOCKER3_NAME}" > /dev/null 2>&1
}
