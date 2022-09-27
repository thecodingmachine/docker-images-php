#!/usr/bin/env bash
. ./config

###########################################################
# Let's check that mbstring is enabled by default
# (it's compiled in PHP)
###########################################################
test_presenceOfMbstring() {
  RESULT=$(docker run ${RUN_OPTIONS} --rm "${REPO}:${TAG_PREFIX}${PHP_VERSION}-${BRANCH}-slim-${BRANCH_VARIANT}" php -m | tail -n +1 | grep --color=never mbstring)
  assert_equals "mbstring" "${RESULT}" "Missing php-mbstring"
}
############################################################
## Let's check that mbstring is enabled by default
## (it's compiled in PHP)
############################################################
test_presenceOfPDO() {
  RESULT=$(docker run ${RUN_OPTIONS} --rm "${REPO}:${TAG_PREFIX}${PHP_VERSION}-${BRANCH}-slim-${BRANCH_VARIANT}" php -m | tail -n +1 | grep --color=never PDO)
  assert_equals "PDO" "${RESULT}" "Missing php-PDO"
}
#################################################################
## Let's check that uploadprogress is enabled explicitly with fat
#################################################################
test_presenceOfUploadprogressOnFat() {
  RESULT=$(docker run ${RUN_OPTIONS} -e "PHP_EXTENSIONS=uploadprogress" --rm "${REPO}:${TAG_PREFIX}${PHP_VERSION}-${BRANCH}-${BRANCH_VARIANT}" php -m | tail -n +1 | grep --color=never uploadprogress)
  assert_equals "uploadprogress" "${RESULT}" "Missing php-uploadprogress"
}
############################################################
## Let's check that the extensions are enabled when composer is run
############################################################
test_enableGdWithComposer() {
  docker $BUILDTOOL -t test/composer_with_gd \
    --build-arg PHP_VERSION="${PHP_VERSION}" --build-arg BRANCH="$BRANCH" \
    --build-arg BRANCH_VARIANT="$BRANCH_VARIANT" --build-arg REPO="$REPO" --build-arg TAG_PREFIX="$TAG_PREFIX" \
    "${SCRIPT_DIR}/assets/composer" > /dev/null 2>&1
  assert_equals "0" "$?" "Docker build failed"
  # This should run ok (the sudo disables environment variables but call to composer proxy does not trigger PHP ini file regeneration)
  docker run ${RUN_OPTIONS} --rm test/composer_with_gd sudo composer update > /dev/null 2>&1
  assert_equals "0" "$?" "Docker run failed"
}

teardown_suite() {
  docker rmi test/composer_with_gd > /dev/null 2>&1
}
