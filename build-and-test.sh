#!/usr/bin/env bash

set -xe

# Let's replace the "." by a "-" with some bash magic
export BRANCH_VARIANT=`echo "$VARIANT" | sed 's/\./-/g'`
docker build -t thecodingmachine/php:${BRANCH}-${BRANCH_VARIANT} -f Dockerfile.${VARIANT} .

# Post build unit tests
if [[ $VARIANT == cli* ]]; then CONTAINER_CWD=/usr/src/app; else CONTAINER_CWD=/var/www/html; fi
# Default user is 1000
RESULT=`docker run thecodingmachine/php:${BRANCH}-${BRANCH_VARIANT} id -ur`
[[ "$RESULT" = "1000" ]]

# If mounted, default user has the id of the mount directory
mkdir user1999 && sudo chown 1999:1999 user1999
ls -al user1999
RESULT=`docker run -v $(pwd)/user1999:$CONTAINER_CWD thecodingmachine/php:${BRANCH}-${BRANCH_VARIANT} id -ur`
[[ "$RESULT" = "1999" ]]
sudo rm -rf user1999

# Let's check that the "xdebug.remote_host" contains a value different from "no value"
docker run -e PHP_EXTENSION_XDEBUG=1 thecodingmachine/php:7.2-v1-cli php -i | grep xdebug.remote_host| grep -v "no value"

echo "Tests passed with success"
