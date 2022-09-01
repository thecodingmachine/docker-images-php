#!/usr/bin/env bash
. ./config

############################################################
## Let's check that the access to cron will fail with a message
############################################################
test_displayErrorWhenMissing() {
  RESULT=$(docker run --rm -e CRON_SCHEDULE_1="* * * * * * *" -e CRON_COMMAND_1="(>&1 echo 'foobar')" \
    "thecodingmachine/php:${PHP_VERSION}-${BRANCH}-slim-${BRANCH_VARIANT}" sleep 1 2>&1 | grep -o 'Cron is not available in this image')
  assert_equals "Cron is not available in this image" "$RESULT"
}
############################################################
## Let's check that the crons are actually sending logs in the right place
############################################################
test_errorLog() {
  RESULT="$(docker run --rm -e CRON_SCHEDULE_1="* * * * * * *" -e CRON_COMMAND_1="(>&1 echo 'foobar')" \
    "thecodingmachine/php:${PHP_VERSION}-${BRANCH}-${BRANCH_VARIANT}" sleep 1 2>&1 | grep -oP 'msg=foobar' | head -n1)"
  assert_equals "msg=foobar" "$RESULT" "std1"
  RESULT="$(docker run --rm -e CRON_SCHEDULE_1="* * * * * * *" -e CRON_COMMAND_1="(>&2 echo 'error')" \
   "thecodingmachine/php:${PHP_VERSION}-${BRANCH}-${BRANCH_VARIANT}" sleep 1 2>&1 | grep -oP 'msg=error' | head -n1)"
  assert_equals "msg=error" "$RESULT" "std2"
}
############################################################
## Let's check that the cron with a user different from root is actually run.
############################################################
test_changeUser() {
  RESULT="$(docker run --rm -e CRON_SCHEDULE_1="* * * * * * *" -e CRON_COMMAND_1="whoami" -e CRON_USER_1="docker" \
    "thecodingmachine/php:${PHP_VERSION}-${BRANCH}-${BRANCH_VARIANT}" sleep 1 2>&1 | grep -oP 'msg=docker' | head -n1)"
  assert_equals "msg=docker" "$RESULT"
}
############################################################
## Let's check that 2 commands split with a ; are run by the same user.
############################################################
test_twoCommandInOneRow() {
  RESULT="$(docker run --rm -e CRON_SCHEDULE_1="* * * * * * *" -e CRON_COMMAND_1="whoami;whoami" -e CRON_USER_1="docker" \
    "thecodingmachine/php:${PHP_VERSION}-${BRANCH}-${BRANCH_VARIANT}" sleep 1 2>&1 | grep -oP 'msg=docker' | wc -l)"
  assert '[ "$RESULT" -gt "1" ]'
}
