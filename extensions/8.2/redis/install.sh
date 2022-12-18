#!/usr/bin/env bash

set -e
export EXTENSION=redis

# we need to do some weird stuff to get memcached working
phpdismod -v $PHP_VERSION igbinary
phpenmod -v $PHP_VERSION igbinary

../docker-install.sh

phpdismod -v $PHP_VERSION igbinary
