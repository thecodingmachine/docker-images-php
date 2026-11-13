#!/usr/bin/env bash
. ./config

if [[ $VARIANT != apache* ]] && [[ $VARIANT != fpm ]]; then
  echo "-- APACHE_LOG_* only applies to Apache"
  return 0;
fi;

IMAGE="${REPO}:${TAG_PREFIX}${PHP_VERSION}-${BRANCH}-slim-${BRANCH_VARIANT}${ARCH_SUFFIX}"

# Starts a container named $1 with the options $2..., and requests a page
start_and_request() {
  local name=$1
  shift
  docker run -d --name "$name" ${RUN_OPTIONS} -v "${SCRIPT_DIR}/assets/":/var/www/html -e PHP_FPM_WEB_SERVER=apache "$@" "${IMAGE}" > /dev/null
  for _ in $(seq 1 60); do
    docker exec "$name" curl -sf -o /dev/null -A 'test-agent' "http://localhost/apache/remote_addr.php?q=1" && break
    sleep 1
  done
  sleep 1
}

############################################################
## The json format writes a JSON object per request on stdout
############################################################
test_jsonFormat() {
  start_and_request "${JSON_NAME}" -e APACHE_LOG_FORMAT=json
  LINE="$(docker logs "${JSON_NAME}" 2>/dev/null | grep 'remote_addr.php' | tail -n 1)"
  assert_equals "200 /apache/remote_addr.php?q=1 test-agent" \
    "$(docker exec "${JSON_NAME}" php -r '$l = json_decode($argv[1], true); echo $l["status"], " ", $l["uri"], " ", $l["user_agent"];' "$LINE")"
}
############################################################
## A custom format is used as is, quotes included
############################################################
test_customFormat() {
  start_and_request "${CUSTOM_NAME}" -e 'APACHE_LOG_FORMAT=custom %>s "%U"'
  assert_matches '^custom 200 "/apache/remote_addr.php"$' "$(docker logs "${CUSTOM_NAME}" 2>/dev/null | grep 'remote_addr.php' | tail -n 1)"
}
############################################################
## APACHE_LOG_OUTPUT=file writes the logs in dated files instead of stdout
############################################################
test_fileOutput() {
  start_and_request "${FILE_NAME}" -e APACHE_LOG_OUTPUT=file
  assert_matches 'remote_addr.php' "$(docker exec "${FILE_NAME}" cat "/var/log/apache2/access.$(date -u +%Y-%m-%d).log")"
  assert "test -z \"\$(docker logs ${FILE_NAME} 2>/dev/null | grep remote_addr.php)\"" "The access log is still written on stdout"
}
############################################################
## The previous log files are gzipped and deleted after APACHE_LOG_RETENTION_DAYS days
############################################################
test_rotation() {
  docker exec -u root "${FILE_NAME}" bash -c 'cd /var/log/apache2 && echo old > access.2020-01-02.log && echo older > access.2020-01-01.log.gz \
    && touch -d "30 days ago" access.2020-01-01.log.gz && echo error > error.2020-01-02.log \
    && APACHE_LOG_RETENTION_DAYS=14 apache-log-rotated.sh /var/log/apache2/access.2020-01-03.log /var/log/apache2/access.2020-01-02.log'
  assert_equals "access.2020-01-02.log.gz error.2020-01-02.log" \
    "$(docker exec "${FILE_NAME}" bash -c 'cd /var/log/apache2 && echo access.2020-* error.2020-*')"
}
############################################################
## APACHE_LOG_MAX_SIZE rotates the file when it reaches its size
############################################################
test_maxSize() {
  start_and_request "${SIZE_NAME}" -e APACHE_LOG_OUTPUT=file -e APACHE_LOG_MAX_SIZE=1K
  for _ in $(seq 1 20); do
    docker exec "${SIZE_NAME}" curl -s -o /dev/null "http://localhost/apache/remote_addr.php?padding=$(printf '%0100d' 0)"
    sleep 0.2
  done
  sleep 2
  assert "test $(docker exec "${SIZE_NAME}" bash -c 'ls /var/log/apache2/access.*' | wc -l) -gt 1" "The access log was not rotated"
  assert "docker exec ${SIZE_NAME} bash -c 'ls /var/log/apache2/access.*.log.gz'" "The previous access logs are not gzipped"
}
############################################################
## An invalid value stops the container at startup
############################################################
test_invalidValues() {
  docker run --rm ${RUN_OPTIONS} -e PHP_FPM_WEB_SERVER=apache -e APACHE_LOG_FORMAT=jsonn "${IMAGE}" true > /dev/null 2>&1
  assert_not_equals "0" "$?" "The container started with APACHE_LOG_FORMAT=jsonn"
  docker run --rm ${RUN_OPTIONS} -e PHP_FPM_WEB_SERVER=apache -e APACHE_LOG_OUTPUT=files "${IMAGE}" true > /dev/null 2>&1
  assert_not_equals "0" "$?" "The container started with APACHE_LOG_OUTPUT=files"
  docker run --rm ${RUN_OPTIONS} -e PHP_FPM_WEB_SERVER=apache -e APACHE_LOG_OUTPUT=file -e APACHE_LOG_MAX_SIZE=100MB "${IMAGE}" true > /dev/null 2>&1
  assert_not_equals "0" "$?" "The container started with APACHE_LOG_MAX_SIZE=100MB"
}

setup_suite() {
  export JSON_NAME="test-apache-logs-json-$(unused_port)"
  export CUSTOM_NAME="test-apache-logs-custom-$(unused_port)"
  export FILE_NAME="test-apache-logs-file-$(unused_port)"
  export SIZE_NAME="test-apache-logs-size-$(unused_port)"
}

teardown_suite() {
  docker rm -f "${JSON_NAME}" "${CUSTOM_NAME}" "${FILE_NAME}" "${SIZE_NAME}" > /dev/null 2>&1
}
