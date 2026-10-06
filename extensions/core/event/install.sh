#!/usr/bin/env bash

set -e
# Sockets is required for event extension to work.
#export EXTENSION="sockets"
export USE_PECL=1
export PECL_EXTENSION="event"
export DEV_DEPENDENCIES="libevent-dev libssl-dev"
export DEPENDENCIES="libevent-2.1-7t64 libevent-core-2.1-7t64 libevent-extra-2.1-7t64 libevent-openssl-2.1-7t64 libevent-pthreads-2.1-7t64 libssl3t64"

../docker-install.sh
