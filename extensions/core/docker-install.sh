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
  PACKAGE_NAME=${PACKAGE_NAME:-$EXTENSION}
  if apt-cache search --names-only "php${PHP_VERSION}-$PACKAGE_NAME" | grep "php${PHP_VERSION}-$PACKAGE_NAME"; then
    set -e
    apt-get install -y --no-install-recommends php${PHP_VERSION}-$PACKAGE_NAME
  else
    set -e
    apt-get install -y --no-install-recommends php-$PACKAGE_NAME
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
      which pecl
    fi

    pecl install $PECL_EXTENSION
    echo "extension=${PHP_EXT_NAME:-${PECL_EXTENSION}}.so" > /etc/php/${PHP_VERSION}/mods-available/${PHP_EXT_NAME:-${PECL_EXTENSION}}.ini
    # Adding this in the list of Ubuntu extensions because we use that list as a base for the modules list.
    # TODO: question: cannot we use /etc/php/mods-available instead???
    touch /var/lib/php/modules/${PHP_VERSION}/registry/${PHP_EXT_NAME:-${PECL_EXTENSION}}
fi

if [ -n "$DEV_DEPENDENCIES" ]; then
    apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false -o APT::AutoRemove::SuggestsImportant=false $DEV_DEPENDENCIES
fi

if [ -n "$EXTENSION" ]; then
    # Let's perform a test
    phpenmod $EXTENSION
    /usr/bin/real_php -m | grep "${PHP_EXT_PHP_NAME:-${PHP_EXT_NAME:-$EXTENSION}}"
    # Check that there is no output on STDERR when starting php:
    OUTPUT=`/usr/bin/real_php -r "echo '';" 2>&1`
    [[ "$OUTPUT" == "" ]]
    # And now, let's disable it!
    phpdismod $EXTENSION
fi

if [ -n "$PECL_EXTENSION" ]; then
    # Let's perform a test
    PHP_EXTENSIONS="${PHP_EXT_NAME:-$PECL_EXTENSION}" /usr/bin/real_php /usr/local/bin/setup_extensions.php | bash
    PHP_EXTENSIONS="${PHP_EXT_NAME:-$PECL_EXTENSION}" /usr/bin/real_php /usr/local/bin/generate_conf.php > /etc/php/${PHP_VERSION}/cli/conf.d/testextension.ini

    /usr/bin/real_php -m | grep "${PHP_EXT_PHP_NAME:-${PHP_EXT_NAME:-$PECL_EXTENSION}}"
    # Check that there is no output on STDERR when starting php:
    OUTPUT=`/usr/bin/real_php -r "echo '';" 2>&1`
    [[ "$OUTPUT" == "" ]]
    PHP_EXTENSIONS="" /usr/bin/real_php /usr/local/bin/setup_extensions.php | bash
    rm /etc/php/${PHP_VERSION}/cli/conf.d/testextension.ini
fi
