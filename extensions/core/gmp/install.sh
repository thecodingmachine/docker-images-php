#!/usr/bin/env bash

set -e
export EXTENSION=gmp
export DEV_DEPENDENCIES="libgmp3-dev"
export DEPENDENCIES="libgmp10 libgmpxx4ldbl"

../docker-install.sh
