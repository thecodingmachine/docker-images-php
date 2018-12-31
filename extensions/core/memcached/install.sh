#!/usr/bin/env bash

set -e
export PECL_EXTENSION=memcached
export DEV_DEPENDENCIES="libmemcached-dev zlib1g-dev"
export DEPENDENCIES="libmemcached11 libmemcachedutil2 zlib1g"

../docker-install.sh
