#!/usr/bin/env bash

set -e
# Sockets is required for event extension to work.
export EXTENSION="sockets"
export PECL_EXTENSION="event"
export DEV_DEPENDENCIES="libevent-dev libssl-dev"
export DEPENDENCIES="libevent-2.0-5 libevent-core-2.0-5 libevent-extra-2.0-5 libevent-openssl-2.0-5 libevent-pthreads-2.0-5"

../docker-install.sh
