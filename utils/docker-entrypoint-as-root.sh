#!/bin/bash

set -e

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

if [ -e /usr/sbin/dma ]; then
    # set sendmail path for PHP
    if [ "$DMA_FROM" = "" ]; then
        DMA_FROM=noreply@example.org
    fi
    export PHP_INI_SENDMAIL_PATH="/usr/sbin/sendmail -t -i -f'$DMA_FROM'"
    if [[ "$DMA_BLOCKING" == "1" ]]; then
        # run in foreground & block until the email really has been sent
        # only documented here as it should not normally be used in production; it's mostly used for testing
        export PHP_INI_SENDMAIL_PATH="${PHP_INI_SENDMAIL_PATH} -D"
    fi

    # generate DMA config based on DMA_CONF_... environment variables
    php /usr/local/bin/generate_dma.php > /etc/dma/dma.conf

    # generate DMA authentication file based on DMA_AUTH_... environment variables
    if [ -n "$DMA_AUTH_USERNAME" ] && [ -n "$DMA_AUTH_PASSWORD" ]; then
        if [ -z "$DMA_CONF_SMARTHOST" ]; then
            echo "DMA_AUTH_USERNAME and DMA_AUTH_PASSWORD are set, but DMA_CONF_SMARTHOST is empty - not attempting authentication" >&2
        else
            echo "$DMA_AUTH_USERNAME|$DMA_CONF_SMARTHOST:$DMA_AUTH_PASSWORD" > /etc/dma/auth.conf
            echo "AUTHPATH /etc/dma/auth.conf" >> /etc/dma/dma.conf
        fi
    fi

    # start BusyBox syslogd to log DMA errors to STDERR
    # unfortunately DMA doesn't support any other way of logging
    # tini will luckily make sure that syslogd will be killed together with any other processes
    syslogd -n -O - -l 6 | grep --color=never -E '\bmail\.\S+\s+dma\b' >&2 &
fi

sudo chown docker:docker /opt/php_env_var_cache.php
/usr/bin/real_php /usr/local/bin/check_php_env_var_changes.php &> /dev/null

/usr/bin/real_php /usr/local/bin/generate_conf.php > /etc/php/${PHP_VERSION}/mods-available/generated_conf.ini
PHP_VERSION="${PHP_VERSION}" /usr/bin/real_php /usr/local/bin/setup_extensions.php | sudo bash

# output on the logs can be done by writing on the "tini" PID. Useful for CRONTAB
TINI_PID=`ps -e | grep tini | awk '{print $1;}'`
/usr/bin/real_php /usr/local/bin/generate_cron.php $TINI_PID > /tmp/generated_crontab
chmod 0644 /tmp/generated_crontab

# If generated_crontab is not empty, start supercronic
if [[ -s /tmp/generated_crontab ]]; then
    supercronic ${SUPERCRONIC_OPTIONS} /tmp/generated_crontab &
fi

if [[ "$IMAGE_VARIANT" == "apache" ]]; then
    /usr/bin/real_php /usr/local/bin/enable_apache_mods.php | bash
fi

if [ -e /etc/container/startup.sh ]; then
    sudo -E -u "#$DOCKER_USER_ID" /etc/container/startup.sh
fi
sudo -E -u "#$DOCKER_USER_ID" sh -c "/usr/bin/real_php /usr/local/bin/startup_commands.php | bash"

if [[ "$APACHE_DOCUMENT_ROOT" == /* ]]; then
  export ABSOLUTE_APACHE_DOCUMENT_ROOT="$APACHE_DOCUMENT_ROOT"
else
  export ABSOLUTE_APACHE_DOCUMENT_ROOT="/var/www/html/$APACHE_DOCUMENT_ROOT"
fi

# We should run the command with the user of the directory... (unless this is Apache, that must run as root...)
if [[ "$@" == "apache2-foreground" ]]; then
    /usr/local/bin/apache-expose-envvars.sh;
    exec "$@";
else
    exec "sudo" "-E" "-H" "-u" "#$DOCKER_USER_ID" "$@";
fi
