#!/bin/bash

set -e

# Let's apply the requested php.ini file
cp /usr/local/etc/php/php.ini-${TEMPLATE_PHP_INI} /usr/local/etc/php/php.ini

DOCKER_FOR_MAC_REMOTE_HOST=`host docker.for.mac.localhost | awk '/has address/ { print $4 }'`

# Let's find the user to use for commands.
# If $DOCKER_USER, let's use this. Otherwise, let's find it.
if [[ "$DOCKER_USER" == "" ]]; then
    # On MacOSX, the owner of the current directory can be completely random (it can be root or docker depending on what happened previously)
    # But MacOSX does not enforce any rights (the docker user can edit any file owned by root).
    # So for MacOSX, we should force the user used to be Docker.
    if [ "$DOCKER_FOR_MAC_REMOTE_HOST" != "127.0.0.1" ]; then
        # we are on a Mac
        DOCKER_USER=docker
    else
        # If not specified, the DOCKER_USER is the ID of the owner of the current working directory (heuristic!)
        DOCKER_USER=`ls -dl $(pwd) | cut -d " " -f 3`
    fi
fi

# DOCKER_USER is a user name if the user exists in the container, otherwise, it is a user ID (from a user on the host).

# If DOCKER_USER is an ID, let's
if [[ "$DOCKER_USER" =~ ^[0-9]+$ ]] ; then
    # MAIN_DIR_USER is a user ID.
    # Let's change the ID of the docker user to match this free id!
    #echo Switching docker id to $DOCKER_USER
    usermod -u $DOCKER_USER -G sudo docker;
    #echo Switching done
    DOCKER_USER=docker
fi

#echo "Docker user: $DOCKER_USER"
DOCKER_USER_ID=`id -ur $DOCKER_USER`
#echo "Docker user id: $DOCKER_USER_ID"

if [ -z "$XDEBUG_REMOTE_HOST" ]; then
    XDEBUG_REMOTE_HOST=`/sbin/ip route|awk '/default/ { print $3 }'`

    # On mac, check that docker.for.mac.localhost exists. it true, use this.
    # Linux systems can report the value exists, but it is bound to localhost. In this case, ignore.
    set +e
    host docker.for.mac.localhost &> /dev/null

    if [[ $? == 0 ]]; then
        # The host exists.
        if [ "$DOCKER_FOR_MAC_REMOTE_HOST" != "127.0.0.1" ]; then
            XDEBUG_REMOTE_HOST=$DOCKER_FOR_MAC_REMOTE_HOST
        fi

    fi
    set -e
fi

unset DOCKER_FOR_MAC_REMOTE_HOST

php /usr/local/bin/generate_conf.php > /usr/local/etc/php/conf.d/generated_conf.ini
php /usr/local/bin/generate_cron.php > /etc/cron.d/generated_crontab
chmod 0644 /etc/cron.d/generated_crontab

if [[ "$IMAGE_VARIANT" == "apache" ]]; then
    php /usr/local/bin/enable_apache_mods.php | bash
fi

cron

if [ -e /etc/container/startup.sh ]; then
    sudo -E -u "#$DOCKER_USER_ID" source /etc/container/startup.sh
fi
sudo -E -u "#$DOCKER_USER_ID" sh -c "php /usr/local/bin/startup_commands.php | bash"

# We should run the command with the user of the directory... (unless this is Apache, that must run as root...)
if [[ "$@" == "/usr/sbin/apachectl -DFOREGROUND" ]]; then
    exec "$@";
else
    exec "sudo" "-E" "-u" "#$DOCKER_USER_ID" "$@";
fi
