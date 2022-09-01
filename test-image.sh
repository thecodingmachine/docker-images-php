#!/usr/bin/env bash
set -eE -o functrace

failure() {
  local lineno=$1
  local msg=$2
  echo "Failed at $lineno: $msg"
}
trap 'failure ${LINENO} "$BASH_COMMAND"' ERR

echo "This testing suite is deprecated : use instead bash_unit in tests-suite directory"
sleep 5

# Use either docker's 'build' command or 'buildx '
export BUILDTOOL="buildx build --load --platform=${PLATFORM:-$(uname -p)}"

# Let's replace the "." by a "-" with some bash magic
export BRANCH_VARIANT="${VARIANT//./-}"

# Build with BuildKit https://docs.docker.com/develop/develop-images/build_enhancements/
export DOCKER_BUILDKIT=1                   # Force use of BuildKit
export BUILDKIT_STEP_LOG_MAX_SIZE=10485760 # output log limit fixed to 10MiB

# Let's check that the extensions can be built using the "ONBUILD" statement
docker $BUILDTOOL -t test/slim_onbuild --build-arg PHP_VERSION="${PHP_VERSION}" --build-arg BRANCH="$BRANCH" --build-arg BRANCH_VARIANT="$BRANCH_VARIANT" tests/slim_onbuild
# This should run ok (the sudo disable environment variables but call to composer proxy does not trigger PHP ini file regeneration)
docker run --rm test/slim_onbuild php -m | grep sockets
docker run --rm test/slim_onbuild php -m | grep pdo_pgsql
docker run --rm test/slim_onbuild php -m | grep pdo_sqlite
docker rmi test/slim_onbuild

# Let's check that the extensions are available for composer using "ARG PHP_EXTENSIONS" statement:
docker $BUILDTOOL -t test/slim_onbuild_composer --build-arg PHP_VERSION="${PHP_VERSION}" --build-arg BRANCH="$BRANCH" --build-arg BRANCH_VARIANT="$BRANCH_VARIANT" tests/slim_onbuild_composer
docker rmi test/slim_onbuild_composer

echo "Running post-build unit tests"
# Post build unit tests
if [[ $VARIANT == cli* ]]; then CONTAINER_CWD=/usr/src/app; else CONTAINER_CWD=/var/www/html; fi
# Default user is 1000
RESULT="$(docker run --rm "thecodingmachine/php:${PHP_VERSION}-${BRANCH}-slim-${BRANCH_VARIANT}" id -ur)"
[[ "$RESULT" == "1000" ]]

# If mounted, default user has the id of the mount directory
mkdir user1999 && docker run --rm -v "$(pwd)":/mnt busybox chown 1999:1999 /mnt/user1999
ls -al user1999
RESULT="$(docker run --rm -v "$(pwd)"/user1999:$CONTAINER_CWD "thecodingmachine/php:${PHP_VERSION}-${BRANCH}-slim-${BRANCH_VARIANT}" id -ur)"
[[ "$RESULT" == "1999" ]]

# Also, the default user can write on stdout and stderr
docker run --rm -v "$(pwd)"/user1999:$CONTAINER_CWD "thecodingmachine/php:${PHP_VERSION}-${BRANCH}-slim-${BRANCH_VARIANT}" bash -c "echo TEST > /proc/self/fd/2"

rm -rf user1999

# and it also works for users with existing IDs in the container
mkdir -p user33
cp tests/apache/composer.json user33/
docker run --rm -v "$(pwd)":/mnt busybox chown -R 33:33 /mnt/user33
ls -al user33
RESULT="$(docker run --rm -v "$(pwd)"/user33:$CONTAINER_CWD "thecodingmachine/php:${PHP_VERSION}-${BRANCH}-slim-${BRANCH_VARIANT}" id -ur)"
[[ "$RESULT" == "33" ]]
RESULT="$(docker run --rm -v "$(pwd)"/user33:$CONTAINER_CWD "thecodingmachine/php:${PHP_VERSION}-${BRANCH}-slim-${BRANCH_VARIANT}" composer update -vvv)"
docker run --rm -v "$(pwd)":/mnt busybox rm -rf /mnt/user33

#Let's check that mbstring is enabled by default (they are compiled in PHP)
docker run --rm "thecodingmachine/php:${PHP_VERSION}-${BRANCH}-slim-${BRANCH_VARIANT}" php -m | grep mbstring
docker run --rm "thecodingmachine/php:${PHP_VERSION}-${BRANCH}-slim-${BRANCH_VARIANT}" php -m | grep PDO
# SQLite is disabled
# docker run --rm "thecodingmachine/php:${PHP_VERSION}-${BRANCH}-slim-${BRANCH_VARIANT}" php -m | grep pdo_sqlite

if [[ $VARIANT == apache* ]]; then
  # Test if environment variables are passed to PHP
  DOCKER_CID="$(docker run --rm -e MYVAR=foo -p "81:80" -d -v "$(pwd)":/var/www/html "thecodingmachine/php:${PHP_VERSION}-${BRANCH}-slim-${BRANCH_VARIANT}")"
  # Let's wait for Apache to start
  sleep 5

  RESULT="$(curl http://localhost:81/tests/test.php)"
  [[ "$RESULT" == "foo" ]]
  docker stop "$DOCKER_CID"

  # Test Apache document root (relative)
  DOCKER_CID="$(docker run --rm -e MYVAR=foo -p "81:80" -d -v "$(pwd)":/var/www/html -e APACHE_DOCUMENT_ROOT=tests "thecodingmachine/php:${PHP_VERSION}-${BRANCH}-slim-${BRANCH_VARIANT}")"
  # Let's wait for Apache to start
  sleep 5
  RESULT="$(curl http://localhost:81/test.php)"
  [[ "$RESULT" == "foo" ]]
  docker stop "$DOCKER_CID"

  # Test Apache document root (absolute)
  DOCKER_CID="$(docker run --rm -e MYVAR=foo -p "81:80" -d -v "$(pwd)":/var/www/foo -e APACHE_DOCUMENT_ROOT=/var/www/foo/tests "thecodingmachine/php:${PHP_VERSION}-${BRANCH}-slim-${BRANCH_VARIANT}")"
  # Let's wait for Apache to start
  sleep 5
  RESULT="$(curl http://localhost:81/test.php)"
  [[ "$RESULT" == "foo" ]]
  docker stop "$DOCKER_CID"

  # Test Apache HtAccess
  DOCKER_CID="$(docker run --rm -p "81:80" -d -v "$(pwd)"/tests/testHtAccess:/foo -e APACHE_DOCUMENT_ROOT=/foo "thecodingmachine/php:${PHP_VERSION}-${BRANCH}-slim-${BRANCH_VARIANT}")"
  # Let's wait for Apache to start
  sleep 5
  RESULT="$(curl http://localhost:81/)"
  [[ "$RESULT" == "foo" ]]
  docker stop "$DOCKER_CID"

  # Test PHP_INI_... variables are correctly handled by apache
  DOCKER_CID="$(docker run --rm -e MYVAR=foo -p "81:80" -d -v "$(pwd)":/var/www/html -e PHP_INI_MEMORY_LIMIT=2G "thecodingmachine/php:${PHP_VERSION}-${BRANCH}-slim-${BRANCH_VARIANT}")"
  # Let's wait for Apache to start
  sleep 5
  RESULT="$(curl http://localhost:81/tests/apache/echo_memory_limit.php)"
  [[ "$RESULT" == "2G" ]]
  docker stop "$DOCKER_CID"
fi

if [[ $VARIANT == fpm* ]]; then
  # Test if environment starts without errors
  DOCKER_CID="$(docker run --rm -p "9000:9000" -d -v "$(pwd)":/var/www/html "thecodingmachine/php:${PHP_VERSION}-${BRANCH}-slim-${BRANCH_VARIANT}")"

  # Let's wait for FPM to start
  sleep 5

  # If the container is still up, it will not fail when stopping.
  docker stop "$DOCKER_CID"
fi

# Let's check that the access to cron will fail with a message
set +e
RESULT="$(docker run --rm -e CRON_SCHEDULE_1="* * * * * * *" -e CRON_COMMAND_1="(>&1 echo 'foobar')" "thecodingmachine/php:${PHP_VERSION}-${BRANCH}-slim-${BRANCH_VARIANT}" sleep 1 2>&1 | grep -o 'Cron is not available in this image')"
set -e
[[ "$RESULT" == "Cron is not available in this image" ]]

# Let's check that the configuration is loaded from the correct php.ini (development, production or imported in the image)
RESULT="$(docker run --rm "thecodingmachine/php:${PHP_VERSION}-${BRANCH}-slim-${BRANCH_VARIANT}" php -i | grep error_reporting)"
[[ "$RESULT" == "error_reporting => 32767 => 32767" ]]

RESULT="$(docker run --rm -e TEMPLATE_PHP_INI=production "thecodingmachine/php:${PHP_VERSION}-${BRANCH}-slim-${BRANCH_VARIANT}" php -i | grep error_reporting)"
[[ "$RESULT" == "error_reporting => 22527 => 22527" ]]

RESULT="$(docker run --rm -v "$(pwd)/tests/php.ini:/etc/php/${PHP_VERSION}/cli/php.ini" "thecodingmachine/php:${PHP_VERSION}-${BRANCH}-slim-${BRANCH_VARIANT}" php -i | grep error_reporting)"
[[ "$RESULT" == "error_reporting => 24575 => 24575" ]]

RESULT="$(docker run --rm -e PHP_INI_ERROR_REPORTING="E_ERROR | E_WARNING" "thecodingmachine/php:${PHP_VERSION}-${BRANCH}-slim-${BRANCH_VARIANT}" php -i | grep error_reporting)"
[[ "$RESULT" == "error_reporting => 3 => 3" ]]

# Tests that environment variables with an equal sign are correctly handled
RESULT="$(docker run --rm -e PHP_INI_SESSION__SAVE_PATH="tcp://localhost?auth=yourverycomplex\"passwordhere" "thecodingmachine/php:${PHP_VERSION}-${BRANCH}-slim-${BRANCH_VARIANT}" php -i | grep "session.save_path")"
[[ "$RESULT" == "session.save_path => tcp://localhost?auth=yourverycomplex\"passwordhere => tcp://localhost?auth=yourverycomplex\"passwordhere" ]]

# Tests that the SMTP parameter is set in uppercase
RESULT="$(docker run --rm -e PHP_INI_SMTP="192.168.0.1" "thecodingmachine/php:${PHP_VERSION}-${BRANCH}-slim-${BRANCH_VARIANT}" php -i | grep "^SMTP")"
[[ "$RESULT" == "SMTP => 192.168.0.1 => 192.168.0.1" ]]

# Tests that environment variables are passed to startup scripts when UID is set
RESULT="$(docker run --rm -e FOO="bar" -e STARTUP_COMMAND_1="env" -e UID=0 "thecodingmachine/php:${PHP_VERSION}-${BRANCH}-slim-${BRANCH_VARIANT}" sleep 1 | grep "FOO")"
[[ "$RESULT" == "FOO=bar" ]]

# Tests that multi-commands are correctly executed  when UID is set
RESULT="$(docker run --rm -e STARTUP_COMMAND_1="cd / && whoami" -e UID=0 "thecodingmachine/php:${PHP_VERSION}-${BRANCH}-slim-${BRANCH_VARIANT}" sleep 1)"
[[ "$RESULT" == "root" ]]

# Tests that startup.sh is correctly executed
docker run --rm -v "$(pwd)"/tests/startup.sh:/etc/container/startup.sh "thecodingmachine/php:${PHP_VERSION}-${BRANCH}-slim-${BRANCH_VARIANT}" php -m | grep "startup.sh executed"

# Tests that disable_functions is commented in php.ini cli
RESULT="$(docker run --rm "thecodingmachine/php:${PHP_VERSION}-${BRANCH}-slim-${BRANCH_VARIANT}" php -i | grep "disable_functions")"
[[ "$RESULT" == "disable_functions => no value => no value" ]]

#################################
# Let's build the "fat" image
#################################
docker $BUILDTOOL -t "thecodingmachine/php:${PHP_VERSION}-${BRANCH}-${BRANCH_VARIANT}" --build-arg PHP_VERSION="${PHP_VERSION}" --build-arg GLOBAL_VERSION="${BRANCH}" -f "Dockerfile.${VARIANT}" .

# Let's check that the crons are actually sending logs in the right place
RESULT="$(docker run --rm -e CRON_SCHEDULE_1="* * * * * * *" -e CRON_COMMAND_1="(>&1 echo 'foobar')" "thecodingmachine/php:${PHP_VERSION}-${BRANCH}-${BRANCH_VARIANT}" sleep 1 2>&1 | grep -oP 'msg=foobar' | head -n1)"
[[ "$RESULT" == "msg=foobar" ]]

RESULT="$(docker run --rm -e CRON_SCHEDULE_1="* * * * * * *" -e CRON_COMMAND_1="(>&2 echo 'error')" "thecodingmachine/php:${PHP_VERSION}-${BRANCH}-${BRANCH_VARIANT}" sleep 1 2>&1 | grep -oP 'msg=error' | head -n1)"
[[ "$RESULT" == "msg=error" ]]

# Let's check that the cron with a user different from root is actually run.
RESULT="$(docker run --rm -e CRON_SCHEDULE_1="* * * * * * *" -e CRON_COMMAND_1="whoami" -e CRON_USER_1="docker" "thecodingmachine/php:${PHP_VERSION}-${BRANCH}-${BRANCH_VARIANT}" sleep 1 2>&1 | grep -oP 'msg=docker' | head -n1)"
[[ "$RESULT" == "msg=docker" ]]

# Let's check that 2 commands split with a ; are run by the same user.
RESULT="$(docker run --rm -e CRON_SCHEDULE_1="* * * * * * *" -e CRON_COMMAND_1="whoami;whoami" -e CRON_USER_1="docker" "thecodingmachine/php:${PHP_VERSION}-${BRANCH}-${BRANCH_VARIANT}" sleep 1 2>&1 | grep -oP 'msg=docker' | wc -l)"
[[ "$RESULT" -gt "1" ]]

# Let's check that mbstring cannot extension cannot be disabled
# Disabled because no more used in setup_extensions.php
#set +e
#docker run --rm -e PHP_EXTENSION_MBSTRING=0 thecodingmachine/php:${PHP_VERSION}-${BRANCH}-${BRANCH_VARIANT} php -i
#[[ "$?" = "1" ]]
#set -e

# Let's check that the "xdebug.client_host" contains a value different from "no value"
docker run --rm -e PHP_EXTENSION_XDEBUG=1 "thecodingmachine/php:${PHP_VERSION}-${BRANCH}-${BRANCH_VARIANT}" php -i | grep xdebug.client_host | grep -v "no value"

# Let's check that "xdebug.mode" is set to "debug" by default
docker run --rm -e PHP_EXTENSION_XDEBUG=1 "thecodingmachine/php:${PHP_VERSION}-${BRANCH}-${BRANCH_VARIANT}" php -i | grep xdebug.mode | grep "debug"

# Let's check that "xdebug.mode" is properly overridden
docker run --rm -e PHP_EXTENSION_XDEBUG=1 -e PHP_INI_XDEBUG__MODE=debug,coverage "thecodingmachine/php:${PHP_VERSION}-${BRANCH}-${BRANCH_VARIANT}" php -i | grep xdebug.mode | grep "debug,coverage"

# TODO

if [[ "${PHP_VERSION}" != "8.1" ]]; then
  # Tests that blackfire + xdebug will output an error
  RESULT="$(docker run --rm -e PHP_EXTENSION_XDEBUG=1 -e PHP_EXTENSION_BLACKFIRE=1 "thecodingmachine/php:${PHP_VERSION}-${BRANCH}-${BRANCH_VARIANT}" php -v 2>&1 | grep 'WARNING: Both Blackfire and Xdebug are enabled. This is not recommended as the PHP engine may not behave as expected. You should strongly consider disabling Xdebug or Blackfire.')"
  [[ "$RESULT" == "WARNING: Both Blackfire and Xdebug are enabled. This is not recommended as the PHP engine may not behave as expected. You should strongly consider disabling Xdebug or Blackfire." ]]
  # Check that blackfire can be enabled
  docker run --rm -e PHP_EXTENSION_BLACKFIRE=1 "thecodingmachine/php:${PHP_VERSION}-${BRANCH}-${BRANCH_VARIANT}" php -m | grep blackfire
fi
# Let's check that the extensions are enabled when composer is run
docker $BUILDTOOL -t test/composer_with_gd --build-arg PHP_VERSION="${PHP_VERSION}" --build-arg BRANCH="$BRANCH" --build-arg BRANCH_VARIANT="$BRANCH_VARIANT" tests/composer

# This should run ok (the sudo disables environment variables but call to composer proxy does not trigger PHP ini file regeneration)
docker run --rm test/composer_with_gd sudo composer update
docker rmi test/composer_with_gd

echo "Tests passed with success"
