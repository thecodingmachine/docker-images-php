#!/usr/bin/env bash

set -e

## http://pecl.php.net/package/swoole
export DEPENDENCIES="zlib1g"
export DEV_DEPENDENCIES="zlib1g-dev"
export USE_PECL=1
export PECL_EXTENSION=swoole-4.8.11
export PHP_EXT_NAME=swoole

../docker-install.sh
