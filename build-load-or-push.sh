#!/usr/bin/env bash

set -eE -o functrace

failure() {
  local lineno=$1
  local msg=$2
  echo "Failed at $lineno: $msg"
}
trap 'failure ${LINENO} "$BASH_COMMAND"' ERR

# Use either docker's 'build' command or 'buildx '
if [ "${PUSH}" == "1" ]; then
  export BUILDTOOL="buildx build --push --platform=${PLATFORM:-linux/amd64}"
else
  export BUILDTOOL="buildx build --load --platform=${PLATFORM:-linux/amd64}"
fi

# Let's replace the "." by a "-" with some bash magic
export BRANCH_VARIANT="${VARIANT//./-}"

# Build with BuildKit https://docs.docker.com/develop/develop-images/build_enhancements/
export DOCKER_BUILDKIT=1                   # Force use of BuildKit
export BUILDKIT_STEP_LOG_MAX_SIZE=10485760 # output log limit fixed to 10MiB

# Let's build the "slim" image.
docker $BUILDTOOL -t "thecodingmachine/php:${PHP_VERSION}-${BRANCH}-slim-${BRANCH_VARIANT}" --build-arg PHP_VERSION="${PHP_VERSION}" --build-arg GLOBAL_VERSION="${BRANCH}" --build-arg BLACKFIRE_VERSION="${BLACKFIRE_VERSION}" -f "Dockerfile.slim.${VARIANT}" .

#################################
# Let's build the "fat" image
#################################
docker $BUILDTOOL -t "thecodingmachine/php:${PHP_VERSION}-${BRANCH}-${BRANCH_VARIANT}" --build-arg PHP_VERSION="${PHP_VERSION}" --build-arg GLOBAL_VERSION="${BRANCH}" -f "Dockerfile.${VARIANT}" .

#################################
# Let's build the "node" images
#################################
docker $BUILDTOOL -t "thecodingmachine/php:${PHP_VERSION}-${BRANCH}-${BRANCH_VARIANT}-node10" --build-arg PHP_VERSION="${PHP_VERSION}" --build-arg GLOBAL_VERSION="${BRANCH}" -f "Dockerfile.${VARIANT}.node10" .
docker $BUILDTOOL -t "thecodingmachine/php:${PHP_VERSION}-${BRANCH}-${BRANCH_VARIANT}-node12" --build-arg PHP_VERSION="${PHP_VERSION}" --build-arg GLOBAL_VERSION="${BRANCH}" -f "Dockerfile.${VARIANT}.node12" .
docker $BUILDTOOL -t "thecodingmachine/php:${PHP_VERSION}-${BRANCH}-${BRANCH_VARIANT}-node14" --build-arg PHP_VERSION="${PHP_VERSION}" --build-arg GLOBAL_VERSION="${BRANCH}" -f "Dockerfile.${VARIANT}.node14" .
docker $BUILDTOOL -t "thecodingmachine/php:${PHP_VERSION}-${BRANCH}-${BRANCH_VARIANT}-node16" --build-arg PHP_VERSION="${PHP_VERSION}" --build-arg GLOBAL_VERSION="${BRANCH}" -f "Dockerfile.${VARIANT}.node16" .


if [ "${PUSH}" == "1" ]; then
  echo "Build and push with success"
else
  echo "Build and load with success"
fi
