#!/bin/bash

set -e

if [[ "$@" == "apache2-foreground" ]]; then
    rm -f /etc/apache2/conf-enabled/expose-env.conf;

    while IFS='=' read -r -d '' n v; do
        if [[ "$n" != "HOME" ]] && [[ "$n" != "_" ]]; then
            printf "PassEnv %s\n" "$n" >> /etc/apache2/conf-enabled/expose-env.conf;
        fi
    done < <(env -0)
fi