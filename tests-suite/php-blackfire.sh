#!/usr/bin/env bash
. ./config

test_enable() {
  # Check that blackfire can be enabled
  docker run ${RUN_OPTIONS} --rm -e PHP_EXTENSION_BLACKFIRE=1 "${REPO}:${TAG_PREFIX}${PHP_VERSION}-${BRANCH}-${BRANCH_VARIANT}" \
    php -m | tail -n +1 | grep -q blackfire
  assert_equals "0" "$?"
}
test_alertConflictWithXDebug() {
  # Skip this test for PHP 8.5 since xdebug is not yet available
  if [[ "${PHP_VERSION}" == "8.5" ]]; then
    echo "-- Skipping blackfire+xdebug conflict test for PHP${PHP_VERSION} (xdebug not available)"
    return 0
  fi
  # Tests that blackfire + xdebug will output an error
  RESULT="$(docker run ${RUN_OPTIONS} --rm -e PHP_EXTENSION_XDEBUG=1 -e PHP_EXTENSION_BLACKFIRE=1 \
    "${REPO}:${TAG_PREFIX}${PHP_VERSION}-${BRANCH}-${BRANCH_VARIANT}" \
    php -v 2>&1 | tail -n +1 | grep 'WARNING: Both Blackfire and Xdebug are enabled. This is not recommended as the PHP engine may not behave as expected. You should strongly consider disabling Xdebug or Blackfire.')"
  assert_equals "WARNING: Both Blackfire and Xdebug are enabled. This is not recommended as the PHP engine may not behave as expected. You should strongly consider disabling Xdebug or Blackfire." "$RESULT"
}

