#!/usr/bin/env bash
. ./config

############################################################
## Default user is 1000
############################################################
test_defaultUserUidIs1000() {
  RESULT="$(docker run ${RUN_OPTIONS} --rm "${REPO}:${TAG_PREFIX}${PHP_VERSION}-${BRANCH}-slim-${BRANCH_VARIANT}" \
    id -ur)"
  assert_equals "0" "$?" "Docker run failed"
  assert_equals "1000" "${RESULT}" "Default user UID missmatch"
}

############################################################
## If mounted, default user has the id
## of the mounted directory
############################################################
test_defaultUserHasUidOfMountedDirectory() {
  mkdir -p "${TMP_DIR}/user1999"
  docker run ${RUN_OPTIONS} --rm -v /tmp:/tmp busybox chown 1999:1999 "${TMP_DIR}/user1999" > /dev/null 2>&1
  RESULT="$(docker run ${RUN_OPTIONS} --rm -v "${TMP_DIR}/user1999":"${CONTAINER_CWD}" "${REPO}:${TAG_PREFIX}${PHP_VERSION}-${BRANCH}-slim-${BRANCH_VARIANT}" \
    id -ur)"
  assert_equals "0" "$?" "Docker run failed"
  assert_equals "1999" "${RESULT}" "Default user UID missmatch with mounted directory"
}

############################################################
## The default user can write on stdout and stderr
############################################################
test_defaultUserCanWriteOnStdoutAndStderr() {
  docker run ${RUN_OPTIONS} --rm -v "${TMP_DIR}/user1999":"${CONTAINER_CWD}" "${REPO}:${TAG_PREFIX}${PHP_VERSION}-${BRANCH}-slim-${BRANCH_VARIANT}" \
    bash -c "echo TEST > /proc/self/fd/2" >> /dev/null
  assert_equals "0" "$?" "Docker run failed"
}

############################################################
## It's also works for users with existing IDs in the container
############################################################
test_defaultUserCanWriteOnStdoutAndStderr() {
  mkdir -p "${TMP_DIR}/user33"
  cat << EOF > "${TMP_DIR}/user33/composer.json"
  {
    "autoload": {
      "psr-4": {
        "\\\\": "."
      }
    }
  }
EOF
  docker run ${RUN_OPTIONS} --rm -v /tmp:/tmp busybox chown -R 33:33 "${TMP_DIR}/user33" > /dev/null 2>&1
  RESULT="$(docker run ${RUN_OPTIONS} --rm -v "${TMP_DIR}/user33":"${CONTAINER_CWD}" "${REPO}:${TAG_PREFIX}${PHP_VERSION}-${BRANCH}-slim-${BRANCH_VARIANT}" \
    id -ur)"
  assert_equals "0" "$?" "Docker run 1 failed"
  assert_equals "33" "${RESULT}" "Default user UID missmatch"
  docker run ${RUN_OPTIONS} --rm -v "${TMP_DIR}/user33":"${CONTAINER_CWD}" "${REPO}:${TAG_PREFIX}${PHP_VERSION}-${BRANCH}-slim-${BRANCH_VARIANT}" \
    composer update -vvv > /dev/null 2>&1
  assert_equals "0" "$?" "Docker run 2 failed"
}


setup_suite() {
  export TMP_DIR="$(mktemp -d)"
  if [[ $VARIANT == cli* ]]; then export CONTAINER_CWD=/usr/src/app; else export CONTAINER_CWD=/var/www/html; fi
}

teardown_suite() {
  if [[ "" != ${TMP_DIR} ]]; then docker run ${RUN_OPTIONS} --rm -v "/tmp":/tmp busybox rm -rf "${TMP_DIR}" > /dev/null 2>&1; fi
}
