#!/usr/bin/env bash
. ./config

############################################################
## Composer binaries can be run by "docker exec" without their path
############################################################
test_composerBinaryWithDockerExec() {
  mkdir -p "${TMP_DIR}/vendor/bin"
  printf '#!/bin/sh\necho composer-bin-ok\n' > "${TMP_DIR}/vendor/bin/composer-bin-test"
  chmod -R a+rX "${TMP_DIR}" && chmod a+x "${TMP_DIR}/vendor/bin/composer-bin-test"
  docker run --name "${COMPOSER_BIN_CONTAINER_NAME}" ${RUN_OPTIONS} --rm -d -v "${TMP_DIR}":"${CONTAINER_CWD}" \
    "${REPO}:${TAG_PREFIX}${PHP_VERSION}-${BRANCH}-slim-${BRANCH_VARIANT}${ARCH_SUFFIX}" sleep 30 > /dev/null
  assert_equals "0" "$?" "Docker run failed"
  RESULT="$(docker exec "${COMPOSER_BIN_CONTAINER_NAME}" composer-bin-test 2>&1)"
  assert_equals "composer-bin-ok" "${RESULT}"
}

setup_suite() {
  export TMP_DIR="$(mktemp -d)"
  export COMPOSER_BIN_CONTAINER_NAME="test-composer-bin-$(unused_port)"
  if [[ $VARIANT == cli* ]]; then export CONTAINER_CWD=/usr/src/app; else export CONTAINER_CWD=/var/www/html; fi
}

teardown_suite() {
  docker rm -f "${COMPOSER_BIN_CONTAINER_NAME}" > /dev/null 2>&1
  if [[ "" != ${TMP_DIR} ]]; then docker run ${RUN_OPTIONS} --rm -v "/tmp":/tmp busybox rm -rf "${TMP_DIR}" > /dev/null 2>&1; fi
}
