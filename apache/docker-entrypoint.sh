#!/bin/sh

usermod -u $UID www-data;
#chown -R www-data:www-data /var/www/html;

if [ -z "$XDEBUG_REMOTE_HOST" ]; then
    XDEBUG_REMOTE_HOST=`/sbin/ip route|awk '/default/ { print $3 }'`

    # On mac, check that docker.for.mac.localhost exists. it true, use this.
    # Linux systems can report the value exists, but it is bound to localhost. In this case, ignore.
    host docker.for.mac.localhost &> /dev/null
    if [ $? == 0 ]; then
        # The host exists.
        DOCKER_FOR_MAC_REMOTE_HOST=`host docker.for.mac.localhost | awk '/has address/ { print $4 }'`
        if [ "$DOCKER_FOR_MAC_REMOTE_HOST" -ne "127.0.0.1" ]; then
            XDEBUG_REMOTE_HOST=$DOCKER_FOR_MAC_REMOTE_HOST
        fi
        unset DOCKER_FOR_MAC_REMOTE_HOST
    fi
fi

php /generate_conf.php > /usr/local/etc/php/conf.d/generated_conf.ini

exec "$@";
