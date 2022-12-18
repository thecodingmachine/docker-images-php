#!/usr/bin/env bash

set -e
if [[ "${TARGETARCH}" == "arm64" ]]; then
  # 176 seconds to execute onto arm64 arch
  >&2 echo "php-rdkafka is not included with arm64 version (because build time is too long)"
  exit 0;
fi
export DEV_DEPENDENCIES="librdkafka-dev"
export DEPENDENCIES="librdkafka1"
PECL_EXTENSION=rdkafka ../docker-install.sh
