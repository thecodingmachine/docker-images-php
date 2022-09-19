#!/usr/bin/env bash
. ./config

############################################################
## Let's check that the extensions can be built
## using the "ONBUILD" statement
############################################################
test_onbluidBase() {
  assert 'onbluidBase' "Image build failed"
  # This should run ok (the sudo disable environment variables but call to composer proxy does not trigger PHP ini file regeneration)
  assert 'onbluidBaseExtensionIsPresent sockets' "Extension sockets not found"
  assert 'onbluidBaseExtensionIsPresent pdo_pgsql' "Extension pdo_pgsql not found"
  assert 'onbluidBaseExtensionIsPresent pdo_sqlite' "Extension pdo_sqlite not found"
}
onbluidBase() {
  docker ${BUILDTOOL} -t ${DOCKER1_NAME} - <<EOF
  ARG PHP_EXTENSIONS="pdo_pgsql pdo_sqlite"
  FROM ${REPO}:${TAG_PREFIX}${PHP_VERSION}-${BRANCH}-slim-${BRANCH_VARIANT}
EOF
  return $?
}
onbluidBaseExtensionIsPresent() {
  docker run ${RUN_OPTIONS} --rm ${DOCKER1_NAME} php -m | grep -q ${1}
  return $?
}

############################################################
## Let's check that the extensions are available for
## composer using "ARG PHP_EXTENSIONS" statement
############################################################
test_composer() {
  assert 'composer' "Image build failed"
}
composer() {
  cat << EOF > "${TMP_DIR}/composer.json"
  {
    "require": {
      "ext-gd": "*"
    }
  }
EOF
  cat <<EOF > "${TMP_DIR}/Dockerfile"
  ARG PHP_EXTENSIONS="gd"
  FROM ${REPO}:${TAG_PREFIX}${PHP_VERSION}-${BRANCH}-slim-${BRANCH_VARIANT}

  COPY composer.json composer.json

  # Let's check that GD is available.
  RUN composer install
EOF
  docker ${BUILDTOOL} -t ${DOCKER2_NAME} "${TMP_DIR}"
  return $?
}

setup_suite() {
  export TMP_DIR="$(mktemp -d)"
  export DOCKER1_NAME="test/slim_onbuild_$(unused_port)"
  export DOCKER2_NAME="test/slim_onbuild_composer_$(unused_port)"
}

teardown_suite() {
  docker rmi --force "${DOCKER1_NAME}" > /dev/null
  docker rmi --force "${DOCKER2_NAME}" > /dev/null
  if [[ "" != ${TMP_DIR} ]]; then docker run ${RUN_OPTIONS} --rm -v "/tmp":/tmp busybox rm -rf "${TMP_DIR}" > /dev/null 2>&1; fi
}
