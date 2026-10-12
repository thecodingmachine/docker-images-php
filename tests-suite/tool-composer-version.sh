#!/usr/bin/env bash
. ./config

############################################################
## COMPOSER_VERSION installs an exact version at the container start
############################################################
test_exactVersion() {
  RESULT="$(docker run ${RUN_OPTIONS} --rm -e COMPOSER_VERSION=2.4.4 \
    "${REPO}:${TAG_PREFIX}${PHP_VERSION}-${BRANCH}-slim-${BRANCH_VARIANT}${ARCH_SUFFIX}" composer --version --no-ansi 2>/dev/null | tail -n +1 | grep -oP '^Composer version \K\S+')"
  assert_equals "2.4.4" "$RESULT"
}
############################################################
## COMPOSER_VERSION installs the latest version of a channel
############################################################
test_channel() {
  RESULT="$(docker run ${RUN_OPTIONS} --rm -e COMPOSER_VERSION=2.2 \
    "${REPO}:${TAG_PREFIX}${PHP_VERSION}-${BRANCH}-slim-${BRANCH_VARIANT}${ARCH_SUFFIX}" composer --version --no-ansi 2>/dev/null | tail -n +1 | grep -oP '^Composer version \K\S+')"
  assert_matches "^2\.2\.[0-9]+$" "$RESULT"
}
############################################################
## ARG COMPOSER_VERSION installs the version during the build
############################################################
test_onbuild() {
  docker ${BUILDTOOL} -t "${DOCKER1_NAME}" - > /dev/null 2>&1 <<EOF
  ARG COMPOSER_VERSION=2.4.4
  FROM ${REPO}:${TAG_PREFIX}${PHP_VERSION}-${BRANCH}-slim-${BRANCH_VARIANT}${ARCH_SUFFIX}
EOF
  assert_equals "0" "$?" "Image build failed"
  RESULT="$(docker run ${RUN_OPTIONS} --rm "${DOCKER1_NAME}" composer --version --no-ansi 2>/dev/null | tail -n +1 | grep -oP '^Composer version \K\S+')"
  assert_equals "2.4.4" "$RESULT"
}

setup_suite() {
  export DOCKER1_NAME="test/composer_version_$(unused_port)"
}

teardown_suite() {
  docker rmi --force "${DOCKER1_NAME}" > /dev/null 2>&1
}
