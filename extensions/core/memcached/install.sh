#!/usr/bin/env bash

set -e
export DEPENDENCIES="php-igbinary php-msgpack"
export EXTENSION=memcached

# we need to do some weird stuff to get memcached working
phpdismod -v $PHP_VERSION igbinary
phpenmod -v $PHP_VERSION igbinary

../docker-install.sh

phpdismod -v $PHP_VERSION igbinary
