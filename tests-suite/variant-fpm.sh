#!/usr/bin/env bash
. ./config

if [[ $VARIANT != fpm ]]; then
  echo "-- There is not an 'fpm' variant"
  return 0;
fi;

# Waits until PHP-FPM answers in the container $1 (and Apache when $2 = apache)
wait_ready() {
  for _ in $(seq 1 60); do
    if docker exec "$1" php-fpm-healthcheck > /dev/null 2>&1 && \
       { [[ "$2" != "apache" ]] || docker exec "$1" curl -s -o /dev/null http://localhost/ > /dev/null 2>&1; }; then
      return 0
    fi
    sleep 0.5
  done
  return 1
}
############################################################
## PHP-FPM starts and answers to FastCGI requests (ping endpoint)
############################################################
test_start() {
  wait_ready "${FPM_CONTAINER_NAME}"
  docker exec "${FPM_CONTAINER_NAME}" php-fpm-healthcheck
  assert_equals "0" "$?" "PHP-FPM healthcheck failed"
}
############################################################
## Process manager is configurable with environment variables
############################################################
test_processManager() {
  RESULT="$(docker run ${RUN_OPTIONS} --rm -e PHP_FPM_PM=static -e PHP_FPM_PM_MAX_CHILDREN=7 \
    "${REPO}:${TAG_PREFIX}${PHP_VERSION}-${BRANCH}-slim-${BRANCH_VARIANT}${ARCH_SUFFIX}" php-fpm -tt 2>&1)"
  assert_matches "pm = static" "$RESULT" "PHP_FPM_PM was not applied"
  assert_matches "pm.max_children = 7" "$RESULT" "PHP_FPM_PM_MAX_CHILDREN was not applied"
}
############################################################
## Graceful stop (SIGQUIT): fast and successful exit
############################################################
test_gracefulStop() {
  docker run --name "${FPM_STOP_CONTAINER_NAME}" ${RUN_OPTIONS} -d \
    "${REPO}:${TAG_PREFIX}${PHP_VERSION}-${BRANCH}-slim-${BRANCH_VARIANT}${ARCH_SUFFIX}" > /dev/null
  wait_ready "${FPM_STOP_CONTAINER_NAME}"
  START=$(date +%s)
  docker stop "${FPM_STOP_CONTAINER_NAME}" > /dev/null 2>&1
  DURATION=$(( $(date +%s) - START ))
  EXIT_CODE="$(docker inspect -f '{{.State.ExitCode}}' "${FPM_STOP_CONTAINER_NAME}")"
  docker rm "${FPM_STOP_CONTAINER_NAME}" > /dev/null 2>&1
  assert_equals "0" "$EXIT_CODE" "PHP-FPM did not stop gracefully"
  assert "test ${DURATION} -lt 5" "PHP-FPM took ${DURATION}s to stop (killed by timeout?)"
}

############################################################
## Apache is not started by default
############################################################
test_noApacheByDefault() {
  RESULT="$(docker exec "${FPM_CONTAINER_NAME}" ps -eo args 2>&1)"
  assert_not_matches "apache2" "$RESULT" "Apache should not be started without PHP_FPM_WEB_SERVER"
}
############################################################
## Apache modules of the built-in Apache can be enabled with APACHE_EXTENSION_*
############################################################
test_apacheEnableModule() {
  RESULT="$(docker run ${RUN_OPTIONS} --rm -e PHP_FPM_WEB_SERVER=apache -e APACHE_EXTENSION_HTTP2=1 \
    "${REPO}:${TAG_PREFIX}${PHP_VERSION}-${BRANCH}-slim-${BRANCH_VARIANT}${ARCH_SUFFIX}" ls /etc/apache2/mods-enabled 2>&1)"
  assert_matches "http2.load" "$RESULT" "APACHE_EXTENSION_HTTP2 was not applied"
  assert_matches "proxy_fcgi.load" "$RESULT" "proxy_fcgi should be enabled"
  assert_not_matches "does not exist" "$RESULT" "a2enmod/a2dismod received an unknown module"
}
############################################################
## An invalid PHP_FPM_WEB_SERVER value is rejected
############################################################
test_invalidWebServer() {
  docker run ${RUN_OPTIONS} --rm -e PHP_FPM_WEB_SERVER=nginx "${REPO}:${TAG_PREFIX}${PHP_VERSION}-${BRANCH}-slim-${BRANCH_VARIANT}${ARCH_SUFFIX}" > /dev/null 2>&1
  assert_not_equals "0" "$?" "An invalid PHP_FPM_WEB_SERVER value should fail"
}
############################################################
## Run apache and try to retrieve var content
############################################################
test_apacheDisplayVarInPhp() {
  RESULT="$(curl -sq http://localhost:${DOCKER1_PORT}/apache/ 2>&1)"
  assert_equals "foo" "$RESULT" "MYVAR was not populate onto php"
}
############################################################
## Run apache with relative document root
############################################################
test_apacheDocumentRootRelative() {
  RESULT="$(curl -sq http://localhost:${DOCKER2_PORT}/ 2>&1)"
  assert_equals "foo" "$RESULT" "Apache document root (relative) does not work properly"
}
############################################################
## Run apache with absolute document root
############################################################
test_apacheDocumentRootAbsolute() {
  RESULT="$(curl -sq http://localhost:${DOCKER3_PORT}/ 2>&1)"
  assert_equals "foo" "$RESULT" "Apache document root (absolute) does not work properly"
}
############################################################
## Run apache HtAccess
############################################################
test_apacheHtaccessRewrite() {
  RESULT="$(curl -sq http://localhost:${DOCKER1_PORT}/apache/htaccess/ 2>&1)"
  assert_equals "foo" "$RESULT" "Apache HtAccess RewriteRule was not applied"
}
############################################################
## Test PHP_INI_... variables are correctly handled by PHP-FPM
############################################################
test_apacheChangeMemoryLimit() {
  RESULT="$(curl -sq http://localhost:${DOCKER1_PORT}/apache/echo_memory_limit.php 2>&1 )"
  assert_equals "2G" "$RESULT" "PHP-FPM PHP_INI_MEMORY_LIMIT was not applied"
}
############################################################
## The Authorization header is forwarded to PHP-FPM
############################################################
test_apacheAuthorizationHeader() {
  RESULT="$(curl -sq -H "Authorization: Bearer foo" http://localhost:${DOCKER1_PORT}/apache/authorization.php 2>&1 )"
  assert_equals "Bearer foo" "$RESULT" "Authorization header was not forwarded to PHP-FPM"
}
############################################################
## A missing PHP file is a 404 answered by Apache
############################################################
test_apacheMissingPhpFile() {
  RESULT="$(curl -sq -o /dev/null -w '%{http_code}' http://localhost:${DOCKER1_PORT}/apache/missing.php 2>&1 )"
  assert_equals "404" "$RESULT" "A missing PHP file should return a 404"
}
############################################################
## Apache uses the threaded MPM (mod_php is not loaded)
############################################################
test_apacheMpmEvent() {
  RESULT="$(docker exec "${DOCKER1_NAME}" ls /etc/apache2/mods-enabled/ 2>&1)"
  assert_matches "mpm_event.load" "$RESULT" "mpm_event is not enabled"
  assert_not_matches "mpm_prefork.load" "$RESULT" "mpm_prefork should not be enabled"
}
############################################################
## PHP-FPM healthcheck
############################################################
test_apacheHealthcheck() {
  docker exec "${DOCKER1_NAME}" php-fpm-healthcheck
  assert_equals "0" "$?" "PHP-FPM healthcheck failed"
}
############################################################
## Graceful stop: fast and successful exit
############################################################
test_apacheGracefulStop() {
  docker run --name "${STOP_NAME}" ${RUN_OPTIONS} -d -e PHP_FPM_WEB_SERVER=apache \
    "${REPO}:${TAG_PREFIX}${PHP_VERSION}-${BRANCH}-slim-${BRANCH_VARIANT}${ARCH_SUFFIX}" > /dev/null
  wait_ready "${STOP_NAME}" apache
  START=$(date +%s)
  docker stop "${STOP_NAME}" > /dev/null 2>&1
  DURATION=$(( $(date +%s) - START ))
  EXIT_CODE="$(docker inspect -f '{{.State.ExitCode}}' "${STOP_NAME}")"
  docker rm "${STOP_NAME}" > /dev/null 2>&1
  assert_equals "0" "$EXIT_CODE" "The container did not stop gracefully"
  assert "test ${DURATION} -lt 5" "The container took ${DURATION}s to stop (killed by timeout?)"
}
############################################################
## A stop requested during the initialization is not lost
############################################################
test_stopDuringStartup() {
  for web_server in "" apache; do
    docker run --name "${STARTUP_STOP_NAME}" ${RUN_OPTIONS} -d -e PHP_FPM_WEB_SERVER="${web_server}" \
      "${REPO}:${TAG_PREFIX}${PHP_VERSION}-${BRANCH}-slim-${BRANCH_VARIANT}${ARCH_SUFFIX}" > /dev/null
    sleep 0.3
    START=$(date +%s)
    docker stop "${STARTUP_STOP_NAME}" > /dev/null 2>&1
    DURATION=$(( $(date +%s) - START ))
    docker rm -f "${STARTUP_STOP_NAME}" > /dev/null 2>&1
    assert "test ${DURATION} -lt 5" "Stopping during startup took ${DURATION}s (web server: '${web_server}')"
  done
}
############################################################
## When PHP-FPM dies, the container exits with an error
############################################################
test_apacheFpmCrashStopsContainer() {
  docker run --name "${CRASH_NAME}" ${RUN_OPTIONS} -d -e PHP_FPM_WEB_SERVER=apache \
    "${REPO}:${TAG_PREFIX}${PHP_VERSION}-${BRANCH}-slim-${BRANCH_VARIANT}${ARCH_SUFFIX}" > /dev/null
  wait_ready "${CRASH_NAME}" apache
  docker exec -u root "${CRASH_NAME}" pkill -KILL -f "php-fpm: master" > /dev/null 2>&1
  EXIT_CODE="$(timeout 10 docker wait "${CRASH_NAME}")"
  docker rm -f "${CRASH_NAME}" > /dev/null 2>&1
  assert_not_equals "0" "${EXIT_CODE:-0}" "The container should exit with an error when PHP-FPM dies"
}

setup_suite() {
  export FPM_CONTAINER_NAME="test-fpm-$(unused_port)"
  export FPM_STOP_CONTAINER_NAME="test-fpm-stop-$(unused_port)"
  export STARTUP_STOP_NAME="test-fpm-startup-stop-$(unused_port)"
  docker run --name "${FPM_CONTAINER_NAME}" ${RUN_OPTIONS} --rm -e MYVAR=foo -e PHP_INI_MEMORY_LIMIT=2G -p "$(unused_port):9000" -d -v "${SCRIPT_DIR}/assets/":/var/www/html \
    "${REPO}:${TAG_PREFIX}${PHP_VERSION}-${BRANCH}-slim-${BRANCH_VARIANT}${ARCH_SUFFIX}" > /dev/null
  assert_equals "0" "$?" "Docker run failed"
  # Built-in Apache (PHP_FPM_WEB_SERVER=apache)
  export STOP_NAME="test-fpm-builtin-apache-stop-$(unused_port)"
  export CRASH_NAME="test-fpm-builtin-apache-crash-$(unused_port)"
  # SETUP apache1
  export DOCKER1_PORT="$(unused_port)"
  export DOCKER1_NAME="test-fpm-builtin-apache1-${DOCKER1_PORT}"
  docker run --name "${DOCKER1_NAME}" ${RUN_OPTIONS} --rm -e MYVAR=foo -e PHP_INI_MEMORY_LIMIT=2G -e PHP_FPM_WEB_SERVER=apache -p "${DOCKER1_PORT}:80" -d -v "${SCRIPT_DIR}/assets/":/var/www/html \
    "${REPO}:${TAG_PREFIX}${PHP_VERSION}-${BRANCH}-slim-${BRANCH_VARIANT}${ARCH_SUFFIX}" > /dev/null
  assert_equals "0" "$?" "Docker run failed"
  # SETUP apache2
  export DOCKER2_PORT="$(unused_port)"
  export DOCKER2_NAME="test-fpm-builtin-apache2-${DOCKER2_PORT}"
  docker run --name "${DOCKER2_NAME}" ${RUN_OPTIONS} --rm -e MYVAR=foo -e APACHE_DOCUMENT_ROOT=apache -e PHP_FPM_WEB_SERVER=apache -p "${DOCKER2_PORT}:80" -d -v "${SCRIPT_DIR}/assets/":/var/www/html \
    "${REPO}:${TAG_PREFIX}${PHP_VERSION}-${BRANCH}-slim-${BRANCH_VARIANT}${ARCH_SUFFIX}" > /dev/null
  assert_equals "0" "$?" "Docker run failed"
  # SETUP apache3
  export DOCKER3_PORT="$(unused_port)"
  export DOCKER3_NAME="test-fpm-builtin-apache3-${DOCKER3_PORT}"
  docker run --name "${DOCKER3_NAME}" ${RUN_OPTIONS} --rm -e MYVAR=foo -e APACHE_DOCUMENT_ROOT=/var/www/foo/apache -e PHP_FPM_WEB_SERVER=apache -p "${DOCKER3_PORT}:80" -d -v "${SCRIPT_DIR}/assets/":/var/www/foo  \
    "${REPO}:${TAG_PREFIX}${PHP_VERSION}-${BRANCH}-slim-${BRANCH_VARIANT}${ARCH_SUFFIX}" > /dev/null
  assert_equals "0" "$?" "Docker run failed"
  # Let's wait for Apache to start
  waitfor http://localhost:${DOCKER1_PORT}
  waitfor http://localhost:${DOCKER2_PORT}
  waitfor http://localhost:${DOCKER3_PORT}
}

teardown_suite() {
  docker stop "${FPM_CONTAINER_NAME}" "${DOCKER1_NAME}" "${DOCKER2_NAME}" "${DOCKER3_NAME}" > /dev/null 2>&1
  docker rm -f "${FPM_STOP_CONTAINER_NAME}" "${STOP_NAME}" "${CRASH_NAME}" "${STARTUP_STOP_NAME}" > /dev/null 2>&1
}
