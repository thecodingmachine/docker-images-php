#!/usr/bin/env bash

set -e
export DEPENDENCIES="zlib1g"
EXTENSION=swoole ../docker-install.sh

## http://pecl.php.net/package/swoole
#export DEV_DEPENDENCIES="zlib1g-dev"
#export USE_PECL=1
#PECL_EXTENSION=swoole ./docker-install.sh
