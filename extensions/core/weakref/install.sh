#!/usr/bin/env bash

set -e
export PECL_EXTENSION=weakref-beta
export PHP_EXT_NAME=weakref # name of the extension (to put in PHP_EXTENSIONS variable)
export PHP_EXT_PHP_NAME=Weakref # name of the extension (as displayed in the output of "php -m")

../docker-install.sh
