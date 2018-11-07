#!/usr/bin/env bash


export EXTENSION=pgsql
export DEV_DEPENDENCIES="libpq-dev"
export DEPENDENCIES="libpq5 libc6"

../docker-install.sh
