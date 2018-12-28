#!/usr/bin/env bash

set -e
export EXTENSION=zip
export DEV_DEPENDENCIES="libzip-dev"
export DEPENDENCIES="libzip4"

../docker-install.sh
