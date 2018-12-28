#!/usr/bin/env bash

set -e
# Comments: MCrypt is deprecated and usage is generally discouraged. Provided here for legacy apps only.

export EXTENSION=mcrypt
export DEV_DEPENDENCIES="libmcrypt-dev"
export DEPENDENCIES="libmcrypt4"

../docker-install.sh
