#!/usr/bin/env bash
. ./config

# Let's check that the configuration is loaded from the correct php.ini (development, production or imported in the image)
############################################################
## Templates
############################################################
test_templateDefaultErrorReporting() {
  RESULT="$(docker run ${RUN_OPTIONS} --rm "${REPO}:${TAG_PREFIX}${PHP_VERSION}-${BRANCH}-slim-${BRANCH_VARIANT}" php -i | grep error_reporting)"
  assert_equals "error_reporting => 32767 => 32767" "$RESULT" "Wrong default error reporting"
}
test_templateProductionErrorReporting() {
  RESULT="$(docker run ${RUN_OPTIONS} --rm -e TEMPLATE_PHP_INI=production \
    "${REPO}:${TAG_PREFIX}${PHP_VERSION}-${BRANCH}-slim-${BRANCH_VARIANT}" php -i | grep error_reporting)"
  assert_equals "error_reporting => 22527 => 22527" "$RESULT" "Wrong production error reporting"
}
test_templateCustomErrorReporting() {
  RESULT="$(docker run ${RUN_OPTIONS} --rm -v "${SCRIPT_DIR}/assets/php-ini/php.ini:/etc/php/${PHP_VERSION}/cli/php.ini" \
    "${REPO}:${TAG_PREFIX}${PHP_VERSION}-${BRANCH}-slim-${BRANCH_VARIANT}" php -i | grep error_reporting)"
  assert_equals "error_reporting => 24575 => 24575" "$RESULT" "Wrong custom php.ini error reporting"
}
############################################################
## PHP_INI_*
############################################################
test_environmentErrorReporting() {
  RESULT="$(docker run ${RUN_OPTIONS} --rm -e PHP_INI_ERROR_REPORTING="E_ERROR | E_WARNING" \
    "${REPO}:${TAG_PREFIX}${PHP_VERSION}-${BRANCH}-slim-${BRANCH_VARIANT}" php -i | grep error_reporting)"
  [[ "$RESULT" == "error_reporting => 3 => 3" ]]
  assert_equals "error_reporting => 3 => 3" "$RESULT" "Wrong Environment error reporting"
}
############################################################
## PHP_INI_SESSION__SAVE_PATH
## Tests that environment variables with an equal sign are correctly handled
############################################################
test_sessionSavePath() {
  RESULT="$(docker run ${RUN_OPTIONS} --rm -e PHP_INI_SESSION__SAVE_PATH="tcp://localhost?auth=yourverycomplex\"passwordhere" \
    "${REPO}:${TAG_PREFIX}${PHP_VERSION}-${BRANCH}-slim-${BRANCH_VARIANT}" php -i | grep "session.save_path")"
  [[ "$RESULT" == "" ]]
  assert_equals "session.save_path => tcp://localhost?auth=yourverycomplex\"passwordhere => tcp://localhost?auth=yourverycomplex\"passwordhere" "$RESULT" "Wrong Environment PHP_INI_SESSION__SAVE_PATH"
}
############################################################
## PHP_INI_SMTP
## Tests that the SMTP parameter is set in uppercase
############################################################
test_smtp() {
  RESULT="$(docker run ${RUN_OPTIONS} --rm -e PHP_INI_SMTP="192.168.0.1" \
    "${REPO}:${TAG_PREFIX}${PHP_VERSION}-${BRANCH}-slim-${BRANCH_VARIANT}" php -i | grep "^SMTP")"
  assert_equals "SMTP => 192.168.0.1 => 192.168.0.1" "$RESULT" "Wrong Environment PHP_INI_SMTP"
}
############################################################
## Tests that disable_functions is commented in php.ini cli
############################################################
test_disabledFunctionsIsCommented() {
  RESULT="$(docker run ${RUN_OPTIONS} --rm \
    "${REPO}:${TAG_PREFIX}${PHP_VERSION}-${BRANCH}-slim-${BRANCH_VARIANT}" php -i | grep "disable_functions")"
  assert_equals "disable_functions => no value => no value" "$RESULT"
}

