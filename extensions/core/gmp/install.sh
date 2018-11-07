#!/usr/bin/env bash


export EXTENSION=gmp
export DEV_DEPENDENCIES="libgmp3-dev"
export DEPENDENCIES="libgmp10 libgmpxx4ldbl"

../docker-install.sh
