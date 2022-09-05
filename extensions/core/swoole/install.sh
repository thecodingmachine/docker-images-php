#!/usr/bin/env bash

set -e

## http://pecl.php.net/package/swoole
export DEPENDENCIES="zlib1g"
export DEV_DEPENDENCIES="zlib1g-dev"
export USE_PECL=1
export PECL_EXTENSION=swoole

../docker-install.sh
