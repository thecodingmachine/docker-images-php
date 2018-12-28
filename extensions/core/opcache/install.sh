#!/usr/bin/env bash

set -e
export EXTENSION=opcache

../docker-install.sh


docker-php-ext-install opcache

php -m | grep "Zend OPcache"
# And now, let's disable it!
rm /usr/local/etc/php/conf.d/docker-php-ext-opcache.ini
