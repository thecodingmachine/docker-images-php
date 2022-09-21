#!/usr/bin/env bash

set -e
if [[ "${TARGETARCH}" == "arm64" ]]; then
  # 188 seconds to execute onto arm64 arch
  >&2 echo "php-ev is not included with arm64 version (because build time is too long)"
  exit 0;
fi
export PECL_EXTENSION=ev

../docker-install.sh


