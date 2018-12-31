#!/usr/bin/env bash

set -e
set -ex

for ext in */; do \
    ext_no_slash=${ext%/}
    if [ -f /usr/local/etc/php/conf.d/docker-php-ext-$ext_no_slash.ini ]; then
        echo "***************** Disabling $ext_no_slash ******************"
        rm -f /usr/local/etc/php/conf.d/docker-php-ext-$ext_no_slash.ini
    fi
done
