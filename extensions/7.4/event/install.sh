#!/usr/bin/env bash

set -e
# Sockets is required for event extension to work.
#export EXTENSION="sockets"
export USE_PECL=1
# The pecl of the Ubuntu php-pear package cannot read the release metadata of event on PHP 7.4: install the archive.
export PECL_EXTENSION=https://pecl.php.net/get/event-3.1.6.tgz
export PHP_EXT_NAME=event
export DEV_DEPENDENCIES="libevent-dev libssl-dev"
export DEPENDENCIES="libevent-2.1-7t64 libevent-core-2.1-7t64 libevent-extra-2.1-7t64 libevent-openssl-2.1-7t64 libevent-pthreads-2.1-7t64 libssl3t64"

../docker-install.sh
