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
  docker ${BUILDTOOL} -t test/slim_onbuild - <<EOF
  ARG PHP_EXTENSIONS="pdo_pgsql pdo_sqlite"
  FROM ${REPO}:${TAG_PREFIX}${PHP_VERSION}-${BRANCH}-slim-${BRANCH_VARIANT}
EOF
  return $?
}
onbluidBaseExtensionIsPresent() {
  docker run ${RUN_OPTIONS} --rm test/slim_onbuild php -m | grep -q ${1}
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
  docker ${BUILDTOOL} -t test/slim_onbuild_composer "${TMP_DIR}"
  return $?
}

setup_suite() {
  export TMP_DIR="$(mktemp -d)"
}

teardown_suite() {
  docker rmi test/slim_onbuild > /dev/null
  docker rmi test/slim_onbuild_composer > /dev/null
  if [[ "" != ${TMP_DIR} ]]; then docker run ${RUN_OPTIONS} --rm -v "/tmp":/tmp busybox rm -rf "${TMP_DIR}" > /dev/null 2>&1; fi
}
