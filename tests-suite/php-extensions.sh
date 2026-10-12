#!/usr/bin/env bash
. ./config

###########################################################
# Let's check that mbstring is enabled by default
# (it's compiled in PHP)
###########################################################
test_presenceOfMbstring() {
  RESULT=$(docker run ${RUN_OPTIONS} --rm "${REPO}:${TAG_PREFIX}${PHP_VERSION}-${BRANCH}-slim-${BRANCH_VARIANT}${ARCH_SUFFIX}" php -m | tail -n +1 | grep --color=never mbstring)
  assert_equals "mbstring" "${RESULT}" "Missing php-mbstring"
}
############################################################
## Let's check that PDO is enabled by default
## (it's compiled in PHP)
############################################################
test_presenceOfPDO() {
  RESULT=$(docker run ${RUN_OPTIONS} --rm "${REPO}:${TAG_PREFIX}${PHP_VERSION}-${BRANCH}-slim-${BRANCH_VARIANT}${ARCH_SUFFIX}" php -m | tail -n +1 | grep --color=never PDO)
  assert_equals "PDO" "${RESULT}" "Missing php-PDO"
}
#################################################################
## Let's check that uploadprogress is enabled explicitly with fat
#################################################################
test_presenceOfUploadprogressOnFat() {
  RESULT=$(docker run ${RUN_OPTIONS} -e "PHP_EXTENSIONS=uploadprogress" --rm "${REPO}:${TAG_PREFIX}${PHP_VERSION}-${BRANCH}-${BRANCH_VARIANT}${ARCH_SUFFIX}" php -m | tail -n +1 | grep --color=never uploadprogress)
  assert_equals "uploadprogress" "${RESULT}" "Missing php-uploadprogress"
}
###################################################################
## Let's check that Imagick can read SVG images on fat
###################################################################
test_imagickSvgOnFat() {
  RESULT=$(docker run ${RUN_OPTIONS} -e "PHP_EXTENSIONS=imagick" --rm "${REPO}:${TAG_PREFIX}${PHP_VERSION}-${BRANCH}-${BRANCH_VARIANT}${ARCH_SUFFIX}" \
    php -r 'echo in_array("SVG", Imagick::queryFormats(), true) ? "SVG" : "missing";' 2>&1)
  assert_equals "SVG" "${RESULT}" "Imagick cannot read SVG images"
}
###################################################################
## Let's check that FFI is enabled explicitly with fat for PHP 7.4+
###################################################################
test_presenceOfFFIOnFat() {
  RESULT=$(docker run ${RUN_OPTIONS} -e "PHP_EXTENSIONS=ffi" --rm "${REPO}:${TAG_PREFIX}${PHP_VERSION}-${BRANCH}-${BRANCH_VARIANT}${ARCH_SUFFIX}" php -m | tail -n +1 | grep --color=never FFI)
  assert_equals "FFI" "${RESULT}" "Missing php-FFI"
}
#################################################################
## Let's check that extensions added in PHP 8.2+ images
## are enabled explicitly with fat
#################################################################
test_presenceOfPhp82ExtensionsOnFat() {
  # Only available on PHP 8.2+
  if [[ "$(printf '%s\n' "$PHP_VERSION" "8.2" | sort -V | head -n 1)" != "8.2" ]]; then return 0; fi
  # Extension name in PHP_EXTENSIONS => name displayed by "php -m"
  declare -A EXTENSIONS=([gnupg]=gnupg [mcrypt]=mcrypt [odbc]=odbc [pdo_odbc]=PDO_ODBC [zstd]=zstd [lz4]=lz4 [decimal]=decimal [inotify]=inotify [opentelemetry]=opentelemetry)
  MODULES=$(docker run ${RUN_OPTIONS} -e "PHP_EXTENSIONS=${!EXTENSIONS[*]}" --rm "${REPO}:${TAG_PREFIX}${PHP_VERSION}-${BRANCH}-${BRANCH_VARIANT}${ARCH_SUFFIX}" php -m | tail -n +1)
  for EXTENSION in "${!EXTENSIONS[@]}"; do
    RESULT=$(echo "${MODULES}" | grep --color=never -x "${EXTENSIONS[$EXTENSION]}")
    assert_equals "${EXTENSIONS[$EXTENSION]}" "${RESULT}" "Missing php-${EXTENSION}"
  done
}
#################################################################
## Let's check that the extensions required by an enabled
## extension are enabled too (even if explicitly disabled)
#################################################################
test_dependenciesOfExtensionsOnFat() {
  MODULES=$(docker run ${RUN_OPTIONS} -e "PHP_EXTENSIONS=memcached mailparse" -e PHP_EXTENSION_IGBINARY=0 -e PHP_EXTENSION_MBSTRING=0 \
    --rm "${REPO}:${TAG_PREFIX}${PHP_VERSION}-${BRANCH}-${BRANCH_VARIANT}${ARCH_SUFFIX}" php -m 2>&1 | tail -n +1)
  assert_equals "0" "$(echo "${MODULES}" | grep -c 'Unable to load dynamic library')" "An extension cannot be loaded"
  for EXTENSION in memcached igbinary msgpack mailparse mbstring redis; do
    RESULT=$(echo "${MODULES}" | grep --color=never -x "${EXTENSION}")
    assert_equals "${EXTENSION}" "${RESULT}" "Missing php-${EXTENSION}"
  done
}
############################################################
## Let's check that the extensions are enabled when composer is run
############################################################
test_enableGdWithComposer() {
  docker $BUILDTOOL -t "${COMPOSER_GD_NAME}" \
    --build-arg PHP_VERSION="${PHP_VERSION}" --build-arg BRANCH="$BRANCH" \
    --build-arg BRANCH_VARIANT="$BRANCH_VARIANT" --build-arg REPO="$REPO" --build-arg TAG_PREFIX="$TAG_PREFIX" --build-arg ARCH_SUFFIX="$ARCH_SUFFIX" \
    "${SCRIPT_DIR}/assets/composer" > /dev/null 2>&1
  assert_equals "0" "$?" "Docker build failed"
  # This should run ok (the sudo disables environment variables but call to composer proxy does not trigger PHP ini file regeneration)
  docker run ${RUN_OPTIONS} --rm "${COMPOSER_GD_NAME}" sudo composer update > /dev/null 2>&1
  assert_equals "0" "$?" "Docker run failed"
}

setup_suite() {
  export COMPOSER_GD_NAME="test/composer_with_gd_$(unused_port)"
}

teardown_suite() {
  docker rmi "${COMPOSER_GD_NAME}" > /dev/null 2>&1
}
