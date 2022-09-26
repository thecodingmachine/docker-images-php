#!/usr/bin/env bash


set -e
if [[ "${PHP_VERSION}" =~ ^7 ]]; then
  if [[ "${TARGETARCH}" == "arm64" ]]; then
    # It's too long to compile onto arm64 arch
    >&2 echo "php-swoole is not included with arm64 version (because build time is too long)"
    exit 0;
  fi
  ## http://pecl.php.net/package/swoole
  export DEPENDENCIES="zlib1g"
  export DEV_DEPENDENCIES="zlib1g-dev"
  export USE_PECL=1
  export PECL_EXTENSION=swoole-4.8.11
  export PHP_EXT_NAME=swoole
else
  export EXTENSION=swoole
fi

../docker-install.sh
