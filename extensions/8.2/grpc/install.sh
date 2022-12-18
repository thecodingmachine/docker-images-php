#!/usr/bin/env bash

set -e
export EXTENSION=grpc

../docker-install.sh

#if [[ "${TARGETARCH}" == "arm64" ]]; then
#  # Need few hours to compile onto arm64 arch
#  >&2 echo "php-grpc is not included with arm64 version (because build time is too long)"
#  exit 0;
#fi
#set -e
#export USE_PECL=1
#export DEV_DEPENDENCIES=zlib1g-dev
#
#export PECL_EXTENSION=grpc
#
#../docker-install.sh
