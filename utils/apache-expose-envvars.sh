#!/bin/bash

set -e

# removes the previous Apache configuration file which is exposing our environment variables
rm -f /etc/apache2/conf-enabled/expose-env.conf;

# alright, now parses all environment variables
while IFS='=' read -r -d '' key value; do
    # the entries HOME and _ are not required and they throw a warning when exposed to Apache:
    # just ignore them...
    if [[ "$key" != "HOME" ]] && [[ "$key" != "_" ]]; then
        # exposes our environment variable ($key) to Apache
        printf "PassEnv %s\n" "$key" >> /etc/apache2/conf-enabled/expose-env.conf;
    fi
done < <(env -0)