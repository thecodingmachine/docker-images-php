#!/usr/bin/env bash
. ./config

if [[ $VARIANT != apache* ]] && [[ $VARIANT != fpm ]]; then
  echo "-- APACHE_TRUSTED_PROXIES only applies to Apache"
  return 0;
fi;

IMAGE="${REPO}:${TAG_PREFIX}${PHP_VERSION}-${BRANCH}-slim-${BRANCH_VARIANT}${ARCH_SUFFIX}"

# Requests the client IP seen by PHP, from the container $1
remote_addr() {
  local from=$1 app=$2
  shift 2
  docker exec "$from" curl -s "$@" "http://${app}/apache/remote_addr.php"
}

wait_app() {
  for _ in $(seq 1 60); do
    docker exec "$1" curl -sf -o /dev/null "http://$2/apache/remote_addr.php" && return 0
    sleep 1
  done
  return 1
}

ip_of() {
  docker inspect -f "{{(index .NetworkSettings.Networks \"${NETWORK}\").IPAddress}}" "$1"
}

############################################################
## The client IP is taken from X-Forwarded-For when the request comes from the proxy
############################################################
test_clientIpFromProxy() {
  assert_equals "203.0.113.7 off" "$(remote_addr "${PROXY_NAME}" "${APP_NAME}" -H 'X-Forwarded-For: 203.0.113.7')"
}
############################################################
## An address added by the client to X-Forwarded-For is ignored
############################################################
test_forgedChainFromProxy() {
  assert_equals "203.0.113.7 off" "$(remote_addr "${PROXY_NAME}" "${APP_NAME}" -H 'X-Forwarded-For: 198.51.100.1, 203.0.113.7')"
}
############################################################
## X-Forwarded-For is ignored when the request does not come from a trusted proxy
############################################################
test_untrustedClient() {
  assert_equals "$(ip_of "${OTHER_NAME}") off" \
    "$(remote_addr "${OTHER_NAME}" "${APP_NAME}" -H 'X-Forwarded-For: 203.0.113.7' -H 'CF-Connecting-IP: 203.0.113.8' -H 'X-Forwarded-Proto: https')"
}
############################################################
## Behind Cloudflare, CF-Connecting-IP is used when the proxy replaced X-Forwarded-For with the Cloudflare address
############################################################
test_cloudflareBehindProxy() {
  assert_equals "203.0.113.9 off" \
    "$(remote_addr "${PROXY_NAME}" "${APP_NAME}" -H 'X-Forwarded-For: 173.245.48.5' -H 'CF-Connecting-IP: 203.0.113.9')"
  assert_equals "203.0.113.9 off" \
    "$(remote_addr "${PROXY_NAME}" "${APP_NAME}" -H 'X-Forwarded-For: 203.0.113.9, 173.245.48.5' -H 'CF-Connecting-IP: 203.0.113.9')"
}
############################################################
## A CF-Connecting-IP sent directly to the proxy, without Cloudflare, is ignored
############################################################
test_forgedCloudflareHeader() {
  assert_equals "198.51.100.6 off" \
    "$(remote_addr "${PROXY_NAME}" "${APP_NAME}" -H 'X-Forwarded-For: 198.51.100.6' -H 'CF-Connecting-IP: 203.0.113.9')"
}
############################################################
## HTTPS is on when the proxy received the request in HTTPS
############################################################
test_httpsFromProxy() {
  assert_equals "203.0.113.7 on" \
    "$(remote_addr "${PROXY_NAME}" "${APP_NAME}" -H 'X-Forwarded-For: 203.0.113.7' -H 'X-Forwarded-Proto: https')"
}
############################################################
## The access log shows the client IP
############################################################
test_accessLog() {
  remote_addr "${PROXY_NAME}" "${APP_NAME}" -H 'X-Forwarded-For: 203.0.113.42' > /dev/null
  sleep 1
  assert_matches "203\.0\.113\.42 - - " "$(docker logs "${APP_NAME}" 2>/dev/null | tail -n +1)"
}
############################################################
## A proxy started after the container is trusted once its name resolves
############################################################
test_lateProxy() {
  docker run -d --name "${LATE_PROXY_NAME}" --network "${NETWORK}" ${RUN_OPTIONS} --entrypoint sleep "${IMAGE}" 600 > /dev/null
  for _ in $(seq 1 45); do
    [[ "$(remote_addr "${LATE_PROXY_NAME}" "${APP_NAME}" -H 'X-Forwarded-For: 203.0.113.5')" == "203.0.113.5 off" ]] && break
    sleep 1
  done
  assert_equals "203.0.113.5 off" "$(remote_addr "${LATE_PROXY_NAME}" "${APP_NAME}" -H 'X-Forwarded-For: 203.0.113.5')"
}

############################################################
## APACHE_TRUSTED_CLOUDFLARE=only refuses the requests of the proxy that did not go through Cloudflare
############################################################
test_cloudflareOnly() {
  docker run -d --name "${ONLY_NAME}" --network "${NETWORK}" ${RUN_OPTIONS} -v "${SCRIPT_DIR}/assets/":/var/www/html \
    -e PHP_FPM_WEB_SERVER=apache -e APACHE_TRUSTED_PROXIES="${PROXY_NAME}" -e APACHE_TRUSTED_CLOUDFLARE=only "${IMAGE}" > /dev/null
  wait_app "${ONLY_NAME}" localhost
  assert_equals "203.0.113.9 off" \
    "$(remote_addr "${PROXY_NAME}" "${ONLY_NAME}" -H 'X-Forwarded-For: 173.245.48.5' -H 'CF-Connecting-IP: 203.0.113.9')"
  assert_equals "403" "$(remote_addr "${PROXY_NAME}" "${ONLY_NAME}" -o /dev/null -w '%{http_code}' -H 'X-Forwarded-For: 198.51.100.6' -H 'CF-Connecting-IP: 203.0.113.9')"
  assert_equals "403" "$(remote_addr "${PROXY_NAME}" "${ONLY_NAME}" -o /dev/null -w '%{http_code}' -H 'X-Forwarded-For: 198.51.100.6' -H 'X-Cloudflare-Hop: 173.245.48.5')"
  # URL rewritten by a .htaccess, like the pretty URLs of WordPress
  assert_equals "203.0.113.9 off" "$(docker exec "${PROXY_NAME}" curl -s "http://${ONLY_NAME}/apache/rewrite/blog/" \
    -H 'X-Forwarded-For: 173.245.48.5' -H 'CF-Connecting-IP: 203.0.113.9')"
  assert_equals "403" "$(docker exec "${PROXY_NAME}" curl -s -o /dev/null -w '%{http_code}' "http://${ONLY_NAME}/apache/rewrite/blog/" \
    -H 'X-Forwarded-For: 198.51.100.6' -H 'CF-Connecting-IP: 203.0.113.9')"
}

############################################################
## An invalid APACHE_TRUSTED_CLOUDFLARE stops the container at startup
############################################################
test_invalidCloudflareValue() {
  OUTPUT="$(docker run --rm ${RUN_OPTIONS} -e PHP_FPM_WEB_SERVER=apache -e APACHE_TRUSTED_CLOUDFLARE=cloudflare "${IMAGE}" true 2>&1)"
  assert_not_equals "0" "$?" "The container started with APACHE_TRUSTED_CLOUDFLARE=cloudflare"
  assert_matches "Invalid APACHE_TRUSTED_CLOUDFLARE value" "${OUTPUT}"
}

############################################################
## The container stops gracefully along with the watcher of the proxies
############################################################
test_gracefulStop() {
  docker run -d --name "${STOP_NAME}" ${RUN_OPTIONS} -v "${SCRIPT_DIR}/assets/":/var/www/html -e PHP_FPM_WEB_SERVER=apache -e APACHE_TRUSTED_PROXIES=10.0.0.1 "${IMAGE}" > /dev/null
  wait_app "${STOP_NAME}" localhost
  START=$(date +%s)
  docker stop "${STOP_NAME}" > /dev/null 2>&1
  DURATION=$(( $(date +%s) - START ))
  EXIT_CODE="$(docker inspect -f '{{.State.ExitCode}}' "${STOP_NAME}")"
  assert_equals "0" "$EXIT_CODE" "The container did not stop gracefully"
  assert "test ${DURATION} -lt 5" "The container took ${DURATION}s to stop (killed by timeout?)"
}

setup_suite() {
  export STOP_NAME="test-trusted-proxies-stop-$(unused_port)"
  export ONLY_NAME="test-trusted-proxies-only-$(unused_port)"
  export NETWORK="test-trusted-proxies-$(unused_port)"
  export APP_NAME="test-trusted-proxies-app-$(unused_port)"
  export PROXY_NAME="test-trusted-proxies-proxy-$(unused_port)"
  export LATE_PROXY_NAME="test-trusted-proxies-late-$(unused_port)"
  export OTHER_NAME="test-trusted-proxies-other-$(unused_port)"
  docker network create "${NETWORK}" > /dev/null
  docker run -d --name "${PROXY_NAME}" --network "${NETWORK}" ${RUN_OPTIONS} --entrypoint sleep "${IMAGE}" 600 > /dev/null
  docker run -d --name "${OTHER_NAME}" --network "${NETWORK}" ${RUN_OPTIONS} --entrypoint sleep "${IMAGE}" 600 > /dev/null
  docker run -d --name "${APP_NAME}" --network "${NETWORK}" ${RUN_OPTIONS} -v "${SCRIPT_DIR}/assets/":/var/www/html \
    -e PHP_FPM_WEB_SERVER=apache -e APACHE_TRUSTED_PROXIES="${PROXY_NAME},${LATE_PROXY_NAME}" -e APACHE_TRUSTED_CLOUDFLARE=1 \
    "${IMAGE}" > /dev/null
  wait_app "${PROXY_NAME}" "${APP_NAME}"
  assert_equals "0" "$?" "Apache did not start"
}

teardown_suite() {
  docker rm -f "${APP_NAME}" "${PROXY_NAME}" "${STOP_NAME}" "${ONLY_NAME}" "${LATE_PROXY_NAME}" "${OTHER_NAME}" > /dev/null 2>&1
  docker network rm "${NETWORK}" > /dev/null 2>&1
}
