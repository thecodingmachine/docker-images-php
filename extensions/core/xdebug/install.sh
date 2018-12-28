#!/usr/bin/env bash

set -e
# We need the "host" command to detect the remote host on MacOS and Windows
PECL_EXTENSION=xdebug DEPENDENCIES="bind9-host" ../docker-install.sh
