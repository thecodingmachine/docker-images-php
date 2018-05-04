#!/usr/bin/env bash

set -xe

# Let's replace the "." by a "-" with some bash magic
export BRANCH_VARIANT=`echo "$VARIANT" | sed 's/\./-/g'`
docker build -t thecodingmachine/php:${BRANCH}-${BRANCH_VARIANT} -f Dockerfile.${VARIANT} .

# Post build unit tests
if [[ $VARIANT == cli* ]]; then CONTAINER_CWD=/usr/src/app; else CONTAINER_CWD=/var/www/html; fi
# Default user is 1000
RESULT=`docker run --rm thecodingmachine/php:${BRANCH}-${BRANCH_VARIANT} id -ur`
[[ "$RESULT" = "1000" ]]

# If mounted, default user has the id of the mount directory
mkdir user1999 && sudo chown 1999:1999 user1999
ls -al user1999
RESULT=`docker run -v $(pwd)/user1999:$CONTAINER_CWD thecodingmachine/php:${BRANCH}-${BRANCH_VARIANT} id -ur`
[[ "$RESULT" = "1999" ]]
sudo rm -rf user1999

# Let's check that mbstring, mysqlnd and ftp are enabled by default (they are compiled in PHP)
docker run --rm thecodingmachine/php:${BRANCH}-${BRANCH_VARIANT} php -m | grep mbstring
docker run --rm thecodingmachine/php:${BRANCH}-${BRANCH_VARIANT} php -m | grep mysqlnd
docker run --rm thecodingmachine/php:${BRANCH}-${BRANCH_VARIANT} php -m | grep ftp

# Let's check that mbstring cannot extension cannot be disabled
set +e
docker run --rm -e PHP_EXTENSION_MBSTRING=0 thecodingmachine/php:${BRANCH}-${BRANCH_VARIANT} php -i
[[ "$?" = "1" ]]
set -e

# Let's check that the "xdebug.remote_host" contains a value different from "no value"
docker run --rm -e PHP_EXTENSION_XDEBUG=1 thecodingmachine/php:${BRANCH}-${BRANCH_VARIANT} php -i | grep xdebug.remote_host| grep -v "no value"

if [[ $VARIANT == apache* ]]; then
    # Test if environment variables are passed to PHP
    DOCKER_CID=`docker run --rm -e MYVAR=foo -p "81:80" -d -v $(pwd):/var/www/html thecodingmachine/php:${BRANCH}-${BRANCH_VARIANT}`

    # Let's wait for Apache to start
    sleep 5

    RESULT=`curl http://localhost:81/tests/test.php`
    [[ "$RESULT" = "foo" ]]
    docker stop $DOCKER_CID
fi

# Let's check that the extensions are enabled when composer is run
docker build --build-arg BRANCH="$BRANCH" --build-arg BRANCH_VARIANT="$BRANCH_VARIANT" tests/composer

# Let's check that the crons are actually sending logs in the right place
RESULT=`docker run --rm -e CRON_SCHEDULE_1="@reboot" -e CRON_COMMAND_1="(>&1 echo "foobar")" thecodingmachine/php:${BRANCH}-${BRANCH_VARIANT} sleep 1`
[[ "$RESULT" = "[Cron] foobar" ]]

docker run --rm -e CRON_SCHEDULE_1="@reboot" -e CRON_COMMAND_1="(>&2 echo "error")" thecodingmachine/php:${BRANCH}-${BRANCH_VARIANT} sleep 1 2>tmp.err
RESULT=`cat tmp.err`
[[ "$RESULT" = "[Cron error] error" ]]
rm tmp.err

# Let's check that the configuration is loaded from the correct php.ini (development, production or imported in the image)
RESULT=`docker run thecodingmachine/php:${BRANCH}-${BRANCH_VARIANT} php -i | grep error_reporting`
[[ "$RESULT" = "error_reporting => 32767 => 32767" ]]

RESULT=`docker run -e TEMPLATE_PHP_INI=production thecodingmachine/php:${BRANCH}-${BRANCH_VARIANT} php -i | grep error_reporting`
[[ "$RESULT" = "error_reporting => 22527 => 22527" ]]

RESULT=`docker run -v $(pwd)/tests/php.ini:/usr/local/etc/php/php.ini thecodingmachine/php:${BRANCH}-${BRANCH_VARIANT} php -i | grep error_reporting`
[[ "$RESULT" = "error_reporting => 24575 => 24575" ]]

echo "Tests passed with success"
