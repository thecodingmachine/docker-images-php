#!/usr/bin/env bash

set -ex

if [ -n "$DEV_DEPENDENCIES" ] || [ -n "$DEPENDENCIES" ]; then
    apt-get install -y --no-install-recommends $DEV_DEPENDENCIES $DEPENDENCIES
fi

if [ -n "$CONFIGURE_OPTIONS" ]; then
    docker-php-ext-configure $EXTENSION $CONFIGURE_OPTIONS
fi

if [ -n "$EXTENSION" ]; then
    docker-php-ext-install $EXTENSION
fi

if [ -n "$PECL_EXTENSION" ]; then
    pecl install $PECL_EXTENSION
fi

if [ -n "$DEV_DEPENDENCIES" ]; then
    apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false -o APT::AutoRemove::SuggestsImportant=false $DEV_DEPENDENCIES
fi

if [ -n "$EXTENSION" ]; then
    # Let's perform a test
    php -m | grep $EXTENSION
    # And now, let's disable it!
    rm -f /usr/local/etc/php/conf.d/docker-php-ext-$EXTENSION.ini
fi

if [ -n "$PECL_EXTENSION" ]; then
    # Let's perform a test
    PHP_EXTENSIONS="$PECL_EXTENSION" php /usr/local/bin/generate_conf.php > /usr/local/etc/php/conf.d/testextension.ini
    php -m | grep $PECL_EXTENSION
    rm /usr/local/etc/php/conf.d/testextension.ini
fi
