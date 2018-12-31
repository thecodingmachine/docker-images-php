#!/usr/bin/env bash

set -e
export EXTENSION=pdo_pgsql
export DEV_DEPENDENCIES="libpq-dev"
export DEPENDENCIES="libpq5 libc6"

../docker-install.sh
