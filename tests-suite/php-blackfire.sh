#!/usr/bin/env bash
. ./config

#if [[ "${PHP_VERSION}" == "8.1" ]]; then
#  echo "-- PHP8.1 not support yet blackfire"
#  return 0
#fi
test_enable() {
  # Check that blackfire can be enabled
  docker run ${RUN_OPTIONS} --rm -e PHP_EXTENSION_BLACKFIRE=1 "${REPO}:${TAG_PREFIX}${PHP_VERSION}-${BRANCH}-${BRANCH_VARIANT}" \
    php -m | tail -n +1 | grep -q blackfire
  assert_equals "0" "$?"
}
test_alertConflictWithXDebug() {
  # Tests that blackfire + xdebug will output an error
  RESULT="$(docker run ${RUN_OPTIONS} --rm -e PHP_EXTENSION_XDEBUG=1 -e PHP_EXTENSION_BLACKFIRE=1 \
    "${REPO}:${TAG_PREFIX}${PHP_VERSION}-${BRANCH}-${BRANCH_VARIANT}" \
    php -v 2>&1 | tail -n +1 | grep 'WARNING: Both Blackfire and Xdebug are enabled. This is not recommended as the PHP engine may not behave as expected. You should strongly consider disabling Xdebug or Blackfire.')"
  assert_equals "WARNING: Both Blackfire and Xdebug are enabled. This is not recommended as the PHP engine may not behave as expected. You should strongly consider disabling Xdebug or Blackfire." "$RESULT"
}

