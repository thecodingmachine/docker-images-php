#!/usr/bin/env bash

set -e
export EXTENSION=redis

# we need to do some weird stuff to get memcached working
phpdismod igbinary
phpenmod igbinary

../docker-install.sh

phpdismod igbinary
