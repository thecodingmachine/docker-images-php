#!/usr/bin/env bash

set -e
export EXTENSION=zip
export DEV_DEPENDENCIES="zlib1g-dev"
export DEPENDENCIES="zlib1g"

../docker-install.sh
