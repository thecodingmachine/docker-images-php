#!/usr/bin/env bash

set -e
# Sockets is required for event extension to work.
#export EXTENSION="sockets"
export PECL_EXTENSION="event"
export DEV_DEPENDENCIES="libevent-dev libssl-dev"
export DEPENDENCIES="libevent-2.1-6 libevent-core-2.1-6 libevent-extra-2.1-6 libevent-openssl-2.1-6 libevent-pthreads-2.1-6 libssl1.1"

../docker-install.sh
