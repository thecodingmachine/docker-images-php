#!/usr/bin/env bash

set -e
export EXTENSION=ffi
# php -m displays "FFI" (uppercase)
export PHP_EXT_PHP_NAME=FFI

../docker-install.sh
