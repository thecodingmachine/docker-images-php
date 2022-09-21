#!/bin/bash

set -e

#exec "sudo" "-E" "/tini" "-g" "-s" "--" "/usr/local/bin/docker-entrypoint-as-root.sh" "$@";
exec "sudo" "-E" "/usr/local/bin/docker-entrypoint-as-root.sh" "$@";
