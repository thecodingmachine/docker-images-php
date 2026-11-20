#!/usr/bin/env bash
. ./config

############################################################
## xdebug
############################################################
test_config() {
  # Docker Engine: the gateway of the container
  RESULT=$(docker run ${RUN_OPTIONS} --rm -e PHP_EXTENSION_XDEBUG=1 "${REPO}:${TAG_PREFIX}${PHP_VERSION}-${BRANCH}-${BRANCH_VARIANT}${ARCH_SUFFIX}" \
    php -r 'echo ini_get("xdebug.client_host");')
  assert_equals "xdebug://gateway" "${RESULT}" '"xdebug.client_host" is not the gateway by default'

  # host.docker.internal when it resolves to a non-loopback address
  RESULT=$(docker run ${RUN_OPTIONS} --rm --add-host host.docker.internal:192.0.2.10 -e PHP_EXTENSION_XDEBUG=1 \
    "${REPO}:${TAG_PREFIX}${PHP_VERSION}-${BRANCH}-${BRANCH_VARIANT}${ARCH_SUFFIX}" php -r 'echo ini_get("xdebug.client_host");')
  assert_equals "192.0.2.10" "${RESULT}" '"xdebug.client_host" is not host.docker.internal'

  # Not when host.docker.internal is a loopback address
  RESULT=$(docker run ${RUN_OPTIONS} --rm --add-host host.docker.internal:127.0.0.1 -e PHP_EXTENSION_XDEBUG=1 \
    "${REPO}:${TAG_PREFIX}${PHP_VERSION}-${BRANCH}-${BRANCH_VARIANT}${ARCH_SUFFIX}" php -r 'echo ini_get("xdebug.client_host");')
  assert_equals "xdebug://gateway" "${RESULT}" '"xdebug.client_host" is a loopback address'

  # XDEBUG_CLIENT_HOST wins
  RESULT=$(docker run ${RUN_OPTIONS} --rm --add-host host.docker.internal:192.0.2.10 -e PHP_EXTENSION_XDEBUG=1 -e XDEBUG_CLIENT_HOST=192.0.2.20 \
    "${REPO}:${TAG_PREFIX}${PHP_VERSION}-${BRANCH}-${BRANCH_VARIANT}${ARCH_SUFFIX}" php -r 'echo ini_get("xdebug.client_host");')
  assert_equals "192.0.2.20" "${RESULT}" 'XDEBUG_CLIENT_HOST is not used'

  # Xdebug enabled for a single command of a running container
  CONTAINER=$(docker run ${RUN_OPTIONS} --rm -d "${REPO}:${TAG_PREFIX}${PHP_VERSION}-${BRANCH}-${BRANCH_VARIANT}${ARCH_SUFFIX}" sleep 60)
  RESULT=$(docker exec -e PHP_EXTENSION_XDEBUG=1 "${CONTAINER}" php -r 'echo ini_get("xdebug.client_host");')
  docker stop -t 0 "${CONTAINER}" > /dev/null
  assert_equals "xdebug://gateway" "${RESULT}" '"xdebug.client_host" is not set with docker exec'

  # Let's check that "xdebug.mode" is set to "debug" by default
  docker run ${RUN_OPTIONS} --rm -e PHP_EXTENSION_XDEBUG=1 "${REPO}:${TAG_PREFIX}${PHP_VERSION}-${BRANCH}-${BRANCH_VARIANT}${ARCH_SUFFIX}" \
    php -i | grep xdebug.mode | grep -q "debug"
  assert_equals "0" "$?" '"xdebug.mode" is not set to "debug" by default'

  # Let's check that "xdebug.mode" is properly overridden
  docker run ${RUN_OPTIONS} --rm -e PHP_EXTENSION_XDEBUG=1 -e PHP_INI_XDEBUG__MODE=debug,coverage \
    "${REPO}:${TAG_PREFIX}${PHP_VERSION}-${BRANCH}-${BRANCH_VARIANT}${ARCH_SUFFIX}" \
    php -i | grep xdebug.mode | grep -q "debug,coverage"
  assert_equals "0" "$?" '"xdebug.mode" is not properly overridden'
}
