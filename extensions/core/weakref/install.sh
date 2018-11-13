#!/usr/bin/env bash


export PECL_EXTENSION=weakref-beta
export PHP_EXT_NAME=weakref # name of the extension (to put in PHP_EXTENSIONS variable)

../docker-install.sh
