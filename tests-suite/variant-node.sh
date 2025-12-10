#!/usr/bin/env bash
. ./config

if [ -z ${NODE+x} ]; then
  echo "-- Node version unset"
  return 0;
fi;
############################################################
## Run node --version, check for vX.Y.Z version string
############################################################
test_nodeVersion() {
  RESULT=$(docker run ${RUN_OPTIONS} --rm "${REPO}:${TAG_PREFIX}${PHP_VERSION}-${BRANCH}-${BRANCH_VARIANT}-node${NODE}${ARCH_SUFFIX}" node --version)
  assert_matches "^v[0-9]+.[0-9]+.[0-9]+" "${RESULT}" "Missing node"
}
############################################################
## Run npm --version, check for X.Y.Z version string
############################################################
test_npmVersion() {
  RESULT=$(docker run ${RUN_OPTIONS} --rm "${REPO}:${TAG_PREFIX}${PHP_VERSION}-${BRANCH}-${BRANCH_VARIANT}-node${NODE}${ARCH_SUFFIX}" npm --version)
  assert_matches "[0-9]+.[0-9]+.[0-9]+" "${RESULT}" "Missing npm"
}
