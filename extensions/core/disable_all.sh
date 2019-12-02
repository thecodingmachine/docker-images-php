#!/usr/bin/env bash

set -e
set -ex

for ext in */; do \
    ext_no_slash=${ext%/}
    if compgen -G "/etc/php/${PHP_VERSION}/cli/conf.d/*-$ext_no_slash.ini" > /dev/null; then
        echo "***************** Disabling $ext_no_slash ******************"
        #rm -f /etc/php/${PHP_VERSION}/cli/conf.d/*-$ext_no_slash.ini
        phpdismod $ext_no_slash
    fi
done
