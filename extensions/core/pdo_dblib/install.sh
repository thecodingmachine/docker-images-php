#!/usr/bin/env bash

set -ex

apt-get install -y --no-install-recommends freetds-dev libsybdb5 libct4
ln -s /usr/lib/x86_64-linux-gnu/libsybdb.a /usr/lib/libsybdb.a
ln -s /usr/lib/x86_64-linux-gnu/libsybdb.so /usr/lib/libsybdb.so

docker-php-ext-install pdo_dblib

apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false -o APT::AutoRemove::SuggestsImportant=false freetds-dev
