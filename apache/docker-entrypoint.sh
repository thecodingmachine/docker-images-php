#!/bin/sh

sedi()
{
    sed --version >/dev/null 2>&1 && sed -i -- "$@" || sed -i "" "$@";
}

usermod -u $UID www-data;
chown -R www-data:www-data /var/www/html;

if [ "$XDEBUG_ENABLED" == "false" ]; then
    sedi "s/\zend_extension/;zend_extension/g" /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini;
else
    export XDEBUG_CONFIG="remote_host=$XDEBUG_REMOTE_HOST";
fi;

exec "$@";