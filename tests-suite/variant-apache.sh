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
  RESULT="$(curl -sq http://localhost:81/apache/)"
  assert_equals "foo" "$RESULT" "MYVAR was not populate onto php"
}
############################################################
## Run apache with relative document root
############################################################
test_documentRootRelative() {
  RESULT="$(curl -sq http://localhost:82/)"
  assert_equals "foo" "$RESULT" "Apache document root (relative) does not work properly"
}
############################################################
## Run apache with absolute document root
############################################################
test_documentRootAbsolute() {
  RESULT="$(curl -sq http://localhost:83/)"
  assert_equals "foo" "$RESULT" "Apache document root (absolute) does not work properly"
}
############################################################
## Run apache HtAccess
############################################################
test_htaccessRewrite() {
  RESULT="$(curl -sq http://localhost:81/apache/htaccess/)"
  assert_equals "foo" "$RESULT" "Apache HtAccess RewriteRule was not applied"
}
############################################################
## Test PHP_INI_... variables are correctly handled by apache
############################################################
test_changeMemoryLimit() {
  RESULT="$(curl -sq http://localhost:81/apache/echo_memory_limit.php)"
  assert_equals "2G" "$RESULT" "Apache PHP_INI_MEMORY_LIMIT was not applied"
}

setup_suite() {
  # SETUP apache1
  docker run --name test-apache1 ${RUN_OPTIONS} --rm -e MYVAR=foo -e PHP_INI_MEMORY_LIMIT=2G -p "81:80" -d -v "${SCRIPT_DIR}/assets/":/var/www/html \
    "${REPO}:${TAG_PREFIX}${PHP_VERSION}-${BRANCH}-slim-${BRANCH_VARIANT}" > /dev/null
  assert_equals "0" "$?" "Docker run failed"
  # SETUP apache2
  docker run --name test-apache2 ${RUN_OPTIONS} --rm -e MYVAR=foo -e APACHE_DOCUMENT_ROOT=apache -p "82:80" -d -v "${SCRIPT_DIR}/assets/":/var/www/html \
    "${REPO}:${TAG_PREFIX}${PHP_VERSION}-${BRANCH}-slim-${BRANCH_VARIANT}" > /dev/null
  assert_equals "0" "$?" "Docker run failed"
  # SETUP apache3
  docker run --name test-apache3 ${RUN_OPTIONS} --rm -e MYVAR=foo -e APACHE_DOCUMENT_ROOT=/var/www/foo/apache -p "83:80" -d -v "${SCRIPT_DIR}/assets/":/var/www/foo  \
    "${REPO}:${TAG_PREFIX}${PHP_VERSION}-${BRANCH}-slim-${BRANCH_VARIANT}" > /dev/null
  assert_equals "0" "$?" "Docker run failed"
  sleep 5 # Let's wait for Apache to start
}

teardown_suite() {
  docker stop test-apache1 test-apache2 test-apache3 > /dev/null 2>&1
}
