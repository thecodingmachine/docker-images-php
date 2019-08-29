#!/usr/bin/env bash

set -e
export DEV_DEPENDENCIES="zlib1g-dev"
export DEPENDENCIES="zlib1g"
PECL_EXTENSION=swoole ../docker-install.sh
