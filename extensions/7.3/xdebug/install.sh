#!/usr/bin/env bash
set -e

PECL_EXTENSION=xdebug-2.7.0RC2 PHP_EXT_NAME=xdebug DEPENDENCIES="bind9-host" ../docker-install.sh
