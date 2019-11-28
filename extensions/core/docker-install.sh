#!/usr/bin/env bash

set -e
set -ex

if [ -n "$DEV_DEPENDENCIES" ] || [ -n "$DEPENDENCIES" ]; then
    apt-get install -y --no-install-recommends $DEV_DEPENDENCIES $DEPENDENCIES
fi

if [ -n "$CONFIGURE_OPTIONS" ]; then
    docker-php-ext-configure $EXTENSION $CONFIGURE_OPTIONS
fi

if [ -n "$EXTENSION" ]; then
  set +e
  if apt-cache search --names-only "php${PHP_VERSION}-$EXTENSION" | grep "php${PHP_VERSION}-$EXTENSION"; then
    set -e
    apt-get install -y --no-install-recommends php${PHP_VERSION}-$EXTENSION
  else
    set -e
    apt-get install -y --no-install-recommends php-$EXTENSION
  fi

fi

if [ -n "$PECL_EXTENSION" ]; then
    # if env ready?

    # is phpize installed?
    if which pecl && which phpize; then
      echo "pecl found"
      which pecl
    else
      apt-get install -y --no-install-recommends build-essential php-pear php${PHP_VERSION}-dev pkg-config
    fi

    pecl install $PECL_EXTENSION
fi

if [ -n "$DEV_DEPENDENCIES" ]; then
    apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false -o APT::AutoRemove::SuggestsImportant=false $DEV_DEPENDENCIES
fi

if [ -n "$EXTENSION" ]; then
    # Let's perform a test
    php -m | grep "${PHP_EXT_PHP_NAME:-${PHP_EXT_NAME:-$EXTENSION}}"
    # Check that there is no output on STDERR when starting php:
    OUTPUT=`php -r "echo '';" 2>&1`
    [[ "$OUTPUT" == "" ]]
    # And now, let's disable it!
    rm -f /etc/php/${PHP_VERSION}/cli/conf.d/*-$EXTENSION.ini
    rm -f /etc/php/${PHP_VERSION}/apache/conf.d/*-$EXTENSION.ini
    rm -f /etc/php/${PHP_VERSION}/fpm/conf.d/*-$EXTENSION.ini
fi

if [ -n "$PECL_EXTENSION" ]; then
    # Let's perform a test
    PHP_EXTENSIONS="${PHP_EXT_NAME:-$PECL_EXTENSION}" php /usr/local/bin/generate_conf.php > /etc/php/${PHP_VERSION}/cli/conf.d/testextension.ini
    php -m | grep "${PHP_EXT_PHP_NAME:-${PHP_EXT_NAME:-$PECL_EXTENSION}}"
    # Check that there is no output on STDERR when starting php:
    OUTPUT=`php -r "echo '';" 2>&1`
    [[ "$OUTPUT" == "" ]]
    rm /etc/php/${PHP_VERSION}/cli/conf.d/testextension.ini
fi
