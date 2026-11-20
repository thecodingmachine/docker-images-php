#!/usr/bin/env bash
. ./config

IMAGE="${REPO}:${TAG_PREFIX}${PHP_VERSION}-${BRANCH}-${BRANCH_VARIANT}${ARCH_SUFFIX}"
SCRIPT='function f(int $n): int { return $n < 2 ? $n : f($n - 1) + f($n - 2); } echo f(27), "\n";'

############################################################
## PHP_PROFILER
############################################################
test_profileCommand() {
  for PROFILER in excimer xhprof; do
    RESULT=$(docker run ${RUN_OPTIONS} --rm -e PHP_PROFILER=${PROFILER} "${IMAGE}" bash -c "echo '<?php ${SCRIPT}' > /tmp/f.php && php-profile /tmp/f.php 2>&1")
    assert_matches "Profile: /tmp/php-profiles/.*-cli-f\.summary\.txt" "${RESULT}" "${PROFILER}: no summary"
    assert_matches $'\n'".* f"$'\n' "${RESULT}" "${PROFILER}: the summary does not name the function"
  done
}

test_profileCommandWithSpx() {
  RESULT=$(docker run ${RUN_OPTIONS} --rm -e PHP_PROFILER=spx "${IMAGE}" bash -c "echo '<?php ${SCRIPT}' > /tmp/f.php && php-profile /tmp/f.php 2>&1")
  assert_matches "SPX Report" "${RESULT}" "SPX did not print its report"
}

test_profileCommandWithXdebug() {
  RESULT=$(docker run ${RUN_OPTIONS} --rm -e PHP_PROFILER=xdebug "${IMAGE}" bash -c "echo '<?php ${SCRIPT}' > /tmp/f.php && php-profile /tmp/f.php 2>&1")
  assert_matches "Profile: /tmp/php-profiles/cachegrind.out" "${RESULT}" "Xdebug did not write a profile"
}

test_onlyOnTrigger() {
  RESULT=$(docker run ${RUN_OPTIONS} --rm -e PHP_PROFILER=excimer "${IMAGE}" bash -c \
    "echo '<?php echo 1;' > /tmp/one.php && php /tmp/one.php > /dev/null && ls /tmp/php-profiles | wc -l && PHP_PROFILE=1 php /tmp/one.php > /dev/null && ls /tmp/php-profiles | grep -c summary")
  assert_equals $'0\n1' "${RESULT}" "Profiles written without the trigger, or not with it"
}

test_triggerValue() {
  RESULT=$(docker run ${RUN_OPTIONS} --rm -e PHP_PROFILER=xhprof -e PHP_PROFILER_TRIGGER_VALUE=s3cr3t "${IMAGE}" bash -c \
    "echo '<?php echo 1;' > /tmp/one.php && PHP_PROFILE=1 php /tmp/one.php > /dev/null && ls /tmp/php-profiles | wc -l && PHP_PROFILE=s3cr3t php /tmp/one.php > /dev/null && ls /tmp/php-profiles | grep -c summary")
  assert_equals $'0\n1' "${RESULT}" "The secret trigger is not checked"
}

test_alwaysWithoutTheScriptsOfTheImage() {
  RESULT=$(docker run ${RUN_OPTIONS} --rm -e PHP_PROFILER=excimer -e PHP_PROFILER_TRIGGER=always "${IMAGE}" bash -c \
    "echo '<?php echo 1;' > /tmp/one.php && php /tmp/one.php > /dev/null && ls /tmp/php-profiles | grep -c summary")
  assert_equals "1" "${RESULT}" "The startup scripts of the image are profiled, or the command is not"
}

test_userPrependFile() {
  DIR=$(mktemp -d)
  echo '<?php $prepended = "yes";' > "${DIR}/pre.php"
  echo '<?php echo $prepended;' > "${DIR}/one.php"
  chmod -R a+rX "${DIR}"
  RESULT=$(docker run ${RUN_OPTIONS} --rm -v "${DIR}:/opt/app" -e PHP_PROFILER=excimer -e PHP_INI_AUTO_PREPEND_FILE=/opt/app/pre.php "${IMAGE}" \
    php /opt/app/one.php)
  rm -rf "${DIR}"
  assert_equals "yes" "${RESULT}" "PHP_INI_AUTO_PREPEND_FILE is not run in the global scope"
}

test_invalidProfiler() {
  docker run ${RUN_OPTIONS} --rm -e PHP_PROFILER=foo "${IMAGE}" php -v > /dev/null 2>&1
  assert_not_equals "0" "$?" "PHP_PROFILER=foo is accepted"
}

test_profileTriggerKeepsTheConfiguration() {
  RESULT=$(docker run ${RUN_OPTIONS} --rm -e PHP_PROFILER=excimer "${IMAGE}" bash -c \
    "cat /opt/php_env_fingerprint && echo '<?php echo 1;' > /tmp/one.php && PHP_PROFILE=1 php /tmp/one.php > /dev/null && cat /opt/php_env_fingerprint" | sort -u | wc -l)
  assert_equals "1" "${RESULT}" "PHP_PROFILE regenerates the configuration"
}

test_profileRequest() {
  # Apache serves the requests of the apache variant only
  if [[ "${VARIANT}" != apache* ]]; then
    return
  fi
  CONTAINER=$(docker run ${RUN_OPTIONS} --rm -d -e PHP_PROFILER=xhprof -e PHP_PROFILER_TRIGGER_VALUE=s3cr3t "${IMAGE}")
  docker exec "${CONTAINER}" bash -c "echo '<?php ${SCRIPT}' > /var/www/html/index.php"
  docker exec "${CONTAINER}" bash -c 'for i in $(seq 30); do curl -sf localhost > /dev/null && break; sleep 1; done
    curl -s localhost > /dev/null; curl -s -H "X-PHP-Profile: wrong" localhost > /dev/null
    curl -s -H "X-PHP-Profile: s3cr3t" localhost/index.php > /dev/null; curl -s -b PHP_PROFILE=s3cr3t localhost > /dev/null'
  RESULT=$(docker exec "${CONTAINER}" bash -c 'ls /tmp/php-profiles | grep -c GET-.*summary')
  docker stop -t 0 "${CONTAINER}" > /dev/null
  assert_equals "2" "${RESULT}" "The requests with the trigger are not the only ones profiled"
}

############################################################
## Conflicts
############################################################
test_conflicts() {
  RESULT=$(docker run ${RUN_OPTIONS} --rm -e PHP_PROFILER=excimer -e PHP_EXTENSION_XDEBUG=1 -e PHP_EXTENSION_PCOV=1 "${IMAGE}" php -v 2>&1)
  assert_matches "Xdebug is enabled while PHP_PROFILER=excimer profiles" "${RESULT}" "No warning for Xdebug and a profiler"
  assert_matches "PCOV and Xdebug are enabled" "${RESULT}" "No warning for PCOV and Xdebug"
}
