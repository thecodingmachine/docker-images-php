#!/usr/bin/env bash

set -e
export EXTENSION=pspell
export DEV_DEPENDENCIES="libpspell-dev"
export DEPENDENCIES="libaspell15"

../docker-install.sh
