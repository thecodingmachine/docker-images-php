#!/usr/bin/env bash

# Comments: MCrypt is deprecated and usage is generally discouraged. Provided here for legacy apps only.

export PECL_EXTENSION=mcrypt-1.0.1
export DEV_DEPENDENCIES="libmcrypt-dev"
export DEPENDENCIES="libmcrypt4"

../docker-install.sh
