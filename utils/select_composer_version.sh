#!/bin/bash
# Installs the Composer version $1: an exact version (e.g. 2.4.4) or a channel (1, 2, or 2.2 for the LTS)

set -e

CURRENT_VERSION=$(composer --version --no-ansi 2>/dev/null | grep -oP '^Composer version \K\S+' || true)

case "$1" in
    1|2|2.2)
        [[ "$CURRENT_VERSION" == "$1".* ]] && exit 0
        SELF_UPDATE_ARG="--$1"
        ;;
    *)
        [[ "$CURRENT_VERSION" == "$1" ]] && exit 0
        SELF_UPDATE_ARG="$1"
        ;;
esac

HOME=/root COMPOSER_HOME=/root/.config/composer COMPOSER_ALLOW_SUPERUSER=1 \
    composer self-update --no-interaction --no-progress --clean-backups "$SELF_UPDATE_ARG"
