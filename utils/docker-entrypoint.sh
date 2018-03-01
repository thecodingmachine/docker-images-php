#!/bin/bash

set -e

sudo -E /tini -g -s -- /usr/local/bin/apache-expose-envvars.sh $@;
exec "sudo" "-E" "/tini" "-g" "-s" "--" "/usr/local/bin/docker-entrypoint-as-root.sh" "$@";
