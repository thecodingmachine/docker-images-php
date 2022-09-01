#!/usr/bin/env bash
. ./config

###########################################################
# Let's check that mbstring is enabled by default
# (it's compiled in PHP)
###########################################################
test_presenceOfMbstring() {
  docker run --rm "thecodingmachine/php:${PHP_VERSION}-${BRANCH}-slim-${BRANCH_VARIANT}" php -m | grep -q mbstring
  assert_equals "0" "$?" "Missing php-mbstring"
}
############################################################
## Let's check that mbstring is enabled by default
## (it's compiled in PHP)
############################################################
test_presenceOfPDO() {
  docker run --rm "thecodingmachine/php:${PHP_VERSION}-${BRANCH}-slim-${BRANCH_VARIANT}" php -m | grep -q PDO
  assert_equals "0" "$?" "Missing php-PDO"
}
############################################################
## Let's check that the extensions are enabled when composer is run
############################################################
test_enableGdWithComposer() {
  docker $BUILDTOOL -t test/composer_with_gd --build-arg PHP_VERSION="${PHP_VERSION}" --build-arg BRANCH="$BRANCH" \
    --build-arg BRANCH_VARIANT="$BRANCH_VARIANT" "${SCRIPT_DIR}/assets/composer" > /dev/null 2>&1
  assert_equals "0" "$?" "Docker build failed"
  # This should run ok (the sudo disables environment variables but call to composer proxy does not trigger PHP ini file regeneration)
  docker run --rm test/composer_with_gd sudo composer update > /dev/null 2>&1
  assert_equals "0" "$?" "Docker run failed"
}

teardown_suite() {
  docker rmi test/composer_with_gd > /dev/null 2>&1
}
