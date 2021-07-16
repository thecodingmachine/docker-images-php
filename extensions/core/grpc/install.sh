#!/usr/bin/env bash

set -e
export USE_PECL=1
export DEV_DEPENDENCIES=zlib1g-dev

export PECL_EXTENSION=grpc

../docker-install.sh
