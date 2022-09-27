#!/usr/bin/env bash

set -e
#if [[ "${PHP_VERSION}" =~ ^7 ]]; then
#  export PECL_EXTENSION=uploadprogress
#else
export EXTENSION=uploadprogress
#fi

../docker-install.sh
