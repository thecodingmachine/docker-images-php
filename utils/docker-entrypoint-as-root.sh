#!/bin/bash

set -e

# Stop right away if a graceful stop is requested during the initialization
trap 'exit 0' QUIT
if [[ "$IMAGE_VARIANT" == "apache" ]]; then
    trap 'exit 0' WINCH
fi

# Let's write a file saying the container is started (we are no longer in build mode, useful for php_proxy.sh)
touch /opt/container_started

# Let's apply the requested php.ini file

if [ ! -f /etc/php/${PHP_VERSION}/cli/php.ini ] || [ -L /etc/php/${PHP_VERSION}/cli/php.ini ]; then
    ln -sf /usr/lib/php/${PHP_VERSION}/php.ini-${TEMPLATE_PHP_INI}.cli /etc/php/${PHP_VERSION}/cli/php.ini
fi

if [[ "$IMAGE_VARIANT" == "apache" ]]; then
    ln -sf /usr/lib/php/${PHP_VERSION}/php.ini-${TEMPLATE_PHP_INI} /etc/php/${PHP_VERSION}/apache2/php.ini
fi

if [[ "$IMAGE_VARIANT" == "fpm" ]]; then
    ln -sf /usr/lib/php/${PHP_VERSION}/php.ini-${TEMPLATE_PHP_INI} /etc/php/${PHP_VERSION}/fpm/php.ini
fi

# Built-in web server of the fpm variant
if [[ -n "$PHP_FPM_WEB_SERVER" ]] && [[ "$PHP_FPM_WEB_SERVER" != "apache" ]]; then
    >&2 echo "Invalid PHP_FPM_WEB_SERVER value: '$PHP_FPM_WEB_SERVER' (supported: 'apache', or empty to disable it)"
    exit 1
fi
if [[ "$IMAGE_VARIANT" == "apache" ]] || [[ "$PHP_FPM_WEB_SERVER" == "apache" ]]; then
    WITH_APACHE=1
fi

# Let's find the user to use for commands.
# If $DOCKER_USER, let's use this. Otherwise, let's find it.
if [[ "$DOCKER_USER" == "" ]]; then
    # On MacOSX, the owner of the current directory can be completely random (it can be root or docker depending on what happened previously)
    # But MacOSX does not enforce any rights (the docker user can edit any file owned by root).
    # On Windows, the owner of the current directory is root if mounted
    # But Windows does not enforce any rights either

    # Let's make a test to see if we have those funky rights.
    set +e
    mkdir testing_file_system_rights.foo
    chmod 700 testing_file_system_rights.foo
    su docker -c "touch testing_file_system_rights.foo/somefile > /dev/null 2>&1"
    HAS_CONSISTENT_RIGHTS=$?

    if [[ "$HAS_CONSISTENT_RIGHTS" != "0" ]]; then
        # If not specified, the DOCKER_USER is the owner of the current working directory (heuristic!)
        DOCKER_USER=`ls -dl $(pwd) | cut -d " " -f 3`
    else
        # we are on a Mac or Windows,
        # Most of the cases, we don't care about the rights (they are not respected)
        FILE_OWNER=`ls -dl testing_file_system_rights.foo/somefile | cut -d " " -f 3`
        if [[ "$FILE_OWNER" == "root" ]]; then
            # if the created user belongs to root, we are likely on a Windows host.
            # all files will belong to root, but it does not matter as everybody can write/delete those (0777 access rights)
            DOCKER_USER=docker
        else
            # In case of a NFS mount (common on MacOS), the created files will belong to the NFS user.
            # Apache should therefore have the ID of this user.
            DOCKER_USER=$FILE_OWNER
        fi
    fi

    rm -rf testing_file_system_rights.foo
    set -e

    unset HAS_CONSISTENT_RIGHTS
fi

# DOCKER_USER is a user name if the user exists in the container, otherwise, it is a user ID (from a user on the host).

# A system account of the image that has the ID of DOCKER_USER is moved to a free ID: the docker user takes this ID
SYS_UID_MIN=$(awk '$1 == "SYS_UID_MIN" { print $2 }' /etc/login.defs)
SYS_UID_MAX=$(awk '$1 == "SYS_UID_MAX" { print $2 }' /etc/login.defs)
SYS_UID_MIN=${SYS_UID_MIN:-100}
SYS_UID_MAX=${SYS_UID_MAX:-999}
SYSTEM_ACCOUNT=$(getent passwd "$DOCKER_USER" | cut -d: -f1,3)
SYSTEM_ACCOUNT_NAME=${SYSTEM_ACCOUNT%%:*}
SYSTEM_ACCOUNT_ID=${SYSTEM_ACCOUNT##*:}
if [[ -n "$SYSTEM_ACCOUNT" ]] && [[ "$SYSTEM_ACCOUNT_NAME" != "docker" ]] && (( SYSTEM_ACCOUNT_ID >= SYS_UID_MIN && SYSTEM_ACCOUNT_ID <= SYS_UID_MAX )); then
    FREE_ID=$SYS_UID_MAX
    while getent passwd "$FREE_ID" > /dev/null; do
        FREE_ID=$((FREE_ID - 1))
    done
    sed -i "s/^${SYSTEM_ACCOUNT_NAME}:\([^:]*\):${SYSTEM_ACCOUNT_ID}:/${SYSTEM_ACCOUNT_NAME}:\1:${FREE_ID}:/" /etc/passwd
    DOCKER_USER=$SYSTEM_ACCOUNT_ID
fi
unset SYS_UID_MIN SYS_UID_MAX SYSTEM_ACCOUNT SYSTEM_ACCOUNT_NAME SYSTEM_ACCOUNT_ID FREE_ID

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


# Fix access rights to stdout and stderr
# Note: chown can fail on older versions of Docker (seen failing on Docker 17.06 on CentOS)
set +e
chown $DOCKER_USER /proc/self/fd/{1,2}
set -e

if [ -z "$XDEBUG_CLIENT_HOST" ]; then
    export XDEBUG_CLIENT_HOST=`/sbin/ip route|awk '/default/ { print $3 }'`

    set +e
    # On Windows and MacOS with Docker >= 18.03, check that host.docker.internal exists. it true, use this.
    # Linux systems can report the value exists, but it is bound to localhost. In this case, ignore.
    host -t A host.docker.internal &> /dev/null
    if [[ $? == 0 ]]; then
        # The host exists.
        DOCKER_HOST_INTERNAL=`host -t A host.docker.internal | awk '/has address/ { print $4 }'`
        if [ "$DOCKER_HOST_INTERNAL" != "127.0.0.1" ]; then
            export XDEBUG_CLIENT_HOST=$DOCKER_HOST_INTERNAL
            export REMOTE_HOST_FOUND=1
        fi
    fi

    if [[ "$REMOTE_HOST_FOUND" != "1" ]]; then
      # On mac with Docker < 18.03, check that docker.for.mac.localhost exists. it true, use this.
      # Linux systems can report the value exists, but it is bound to localhost. In this case, ignore.
      host -t A docker.for.mac.localhost &> /dev/null

      if [[ $? == 0 ]]; then
          # The host exists.
          DOCKER_FOR_MAC_REMOTE_HOST=`host -t A docker.for.mac.localhost | awk '/has address/ { print $4 }'`
          if [ "$DOCKER_FOR_MAC_REMOTE_HOST" != "127.0.0.1" ]; then
              export XDEBUG_CLIENT_HOST=$DOCKER_FOR_MAC_REMOTE_HOST
          fi
      fi
    fi
    set -e
fi

unset DOCKER_FOR_MAC_REMOTE_HOST
unset REMOTE_HOST_FOUND

sudo chown docker:docker /opt/php_env_var_cache.php
/usr/bin/real_php -d display_errors=stderr /usr/local/bin/check_php_env_var_changes.php &> /dev/null

/usr/bin/real_php -d display_errors=stderr /usr/local/bin/generate_conf.php > /etc/php/${PHP_VERSION}/mods-available/generated_conf.ini
PHP_VERSION="${PHP_VERSION}" /usr/bin/real_php -d display_errors=stderr /usr/local/bin/setup_extensions.php | sudo bash

# output on the logs can be done by writing on the "tini" PID. Useful for CRONTAB
TINI_PID=`ps -e | grep tini | awk '{print $1;}'`
/usr/bin/real_php -d display_errors=stderr /usr/local/bin/generate_cron.php $TINI_PID > /tmp/generated_crontab
chmod 0644 /tmp/generated_crontab

# If generated_crontab is not empty, start supercronic
if [[ -s /tmp/generated_crontab ]]; then
    supercronic ${SUPERCRONIC_OPTIONS} /tmp/generated_crontab &
fi

if [[ "$WITH_APACHE" == "1" ]]; then
    /usr/bin/real_php -d display_errors=stderr /usr/local/bin/enable_apache_mods.php | bash
fi

if [ -e /etc/container/startup.sh ]; then
    sudo -E -u "#$DOCKER_USER_ID" /etc/container/startup.sh
fi
sudo -E -u "#$DOCKER_USER_ID" sh -c "/usr/bin/real_php -d display_errors=stderr /usr/local/bin/startup_commands.php | bash"

if [[ "$APACHE_DOCUMENT_ROOT" == /* ]]; then
  export ABSOLUTE_APACHE_DOCUMENT_ROOT="$APACHE_DOCUMENT_ROOT"
else
  export ABSOLUTE_APACHE_DOCUMENT_ROOT="/var/www/html/$APACHE_DOCUMENT_ROOT"
fi

# When the PHP-FPM master process runs as root, its workers run with the Apache user
if [[ "$@" == "php-fpm" ]]; then
    FPM_USER_CONF="/etc/php/${PHP_VERSION}/fpm/pool.d/zz-docker-user.conf"
    if [[ "$WITH_APACHE" == "1" ]] || [[ "$DOCKER_USER_ID" == "0" ]]; then
        printf '[www]\nuser = %s\ngroup = %s\n' "$APACHE_RUN_USER" "$APACHE_RUN_GROUP" > "$FPM_USER_CONF"
    else
        rm -f "$FPM_USER_CONF"
    fi
fi

# We should run the command with the user of the directory... (unless this is Apache, that must run as root...)
if [[ "$@" == "apache2-foreground" ]]; then
    /usr/local/bin/apache-expose-envvars.sh;
    exec "$@";
elif [[ "$@" == "php-fpm" ]] && [[ "$WITH_APACHE" == "1" ]]; then
    # Apache and the PHP-FPM master process are started as root
    exec apache2-fpm-foreground;
else
    exec "sudo" "-E" "-H" "-u" "#$DOCKER_USER_ID" "$@";
fi
