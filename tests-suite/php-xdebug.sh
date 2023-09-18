#!/usr/bin/env bash
. ./config

############################################################
## xdebug
############################################################
test_config() {
  # Let's check that the "xdebug.client_host" contains a value different from "no value"
  docker run ${RUN_OPTIONS} --rm -e PHP_EXTENSION_XDEBUG=1 "${REPO}:${TAG_PREFIX}${PHP_VERSION}-${BRANCH}-${BRANCH_VARIANT}" \
    php -i | tail -n +1 | grep xdebug.client_host | grep -v -q "no value"
  assert_equals "0" "$?" '"xdebug.client_host" contains "no value"'

  # Let's check that "xdebug.mode" is set to "debug" by default
  docker run ${RUN_OPTIONS} --rm -e PHP_EXTENSION_XDEBUG=1 "${REPO}:${TAG_PREFIX}${PHP_VERSION}-${BRANCH}-${BRANCH_VARIANT}" \
    php -i | tail -n +1 | grep xdebug.mode | grep -q "debug"
  assert_equals "0" "$?" '"xdebug.mode" is not set to "debug" by default'

  # Let's check that "xdebug.mode" is properly overridden
  docker run ${RUN_OPTIONS} --rm -e PHP_EXTENSION_XDEBUG=1 -e PHP_INI_XDEBUG__MODE=debug,coverage \
    "${REPO}:${TAG_PREFIX}${PHP_VERSION}-${BRANCH}-${BRANCH_VARIANT}" \
    php -i | tail -n +1 | grep xdebug.mode | grep -q "debug,coverage"
  assert_equals "0" "$?" '"xdebug.mode" is not properly overridden'
}
