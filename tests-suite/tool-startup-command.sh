#!/usr/bin/env bash
. ./config

############################################################
## Tests that environment variables are passed to startup scripts when UID is set
############################################################
test_uid() {
  RESULT="$(docker run --rm -e FOO="bar" -e STARTUP_COMMAND_1="env" -e UID=0 \
    "thecodingmachine/php:${PHP_VERSION}-${BRANCH}-slim-${BRANCH_VARIANT}" sleep 1 | grep "FOO")"
  assert_equals "FOO=bar" "$RESULT"
}
############################################################
## Tests that multi-commands are correctly executed  when UID is set
############################################################
test_asRoot() {
  RESULT="$(docker run --rm -e STARTUP_COMMAND_1="cd / && whoami" -e UID=0 \
    "thecodingmachine/php:${PHP_VERSION}-${BRANCH}-slim-${BRANCH_VARIANT}" sleep 1)"
  assert_equals "root" "$RESULT"
}
############################################################
## Tests that startup.sh is correctly executed
############################################################
test_withFile() {
  docker run --rm -v "${SCRIPT_DIR}/assets/startup.sh":/etc/container/startup.sh \
    "thecodingmachine/php:${PHP_VERSION}-${BRANCH}-slim-${BRANCH_VARIANT}" php -m 2>/dev/null | grep -q "startup.sh executed"
  assert_equals "0" "$?"
}
