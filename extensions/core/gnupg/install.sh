#!/usr/bin/env bash

set -e
export PECL_EXTENSION=gnupg
export DEV_DEPENDENCIES="libgpgme11-dev"
export DEPENDENCIES="libgpgme11"

../docker-install.sh
