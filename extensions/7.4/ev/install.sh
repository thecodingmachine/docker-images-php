#!/usr/bin/env bash

set -e
# ev 1.2+ requires PHP 8.0: pin the last version compatible with PHP 7.4.
export USE_PECL=1
export PECL_EXTENSION=ev-1.1.5
export PHP_EXT_NAME=ev

../docker-install.sh
