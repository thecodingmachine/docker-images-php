#!/bin/bash

set -e

if [[ "$UID" -ne "" ]]; then
    if [[ "$IMAGE_VARIANT" -ne "cli" ]]; then
        usermod -u $UID www-data;
    fi
fi
#chown -R www-data:www-data /var/www/html;

if [ -z "$XDEBUG_REMOTE_HOST" ]; then
    XDEBUG_REMOTE_HOST=`/sbin/ip route|awk '/default/ { print $3 }'`

    # On mac, check that docker.for.mac.localhost exists. it true, use this.
    # Linux systems can report the value exists, but it is bound to localhost. In this case, ignore.
    set +e
    host docker.for.mac.localhost &> /dev/null

    if [[ $? == 0 ]]; then
        # The host exists.
        DOCKER_FOR_MAC_REMOTE_HOST=`host docker.for.mac.localhost | awk '/has address/ { print $4 }'`
        if [ "$DOCKER_FOR_MAC_REMOTE_HOST" -ne "127.0.0.1" ]; then
            XDEBUG_REMOTE_HOST=$DOCKER_FOR_MAC_REMOTE_HOST
        fi
        unset DOCKER_FOR_MAC_REMOTE_HOST
    fi
    set -e
fi

php /usr/local/bin/generate_conf.php > /usr/local/etc/php/conf.d/generated_conf.ini
php /usr/local/bin/generate_cron.php > /etc/cron.d/generated_crontab
chmod 0644 /etc/cron.d/generated_crontab

cron
exec "$@";
