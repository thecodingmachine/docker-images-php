#!/usr/bin/env bash

set -e
export EXTENSION=intl
export DEV_DEPENDENCIES="libicu-dev"
export DEPENDENCIES="libicu57"

../docker-install.sh
