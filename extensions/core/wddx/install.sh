#!/usr/bin/env bash

set -e
export EXTENSION=wddx
export DEV_DEPENDENCIES="libxml2-dev"
export DEPENDENCIES="libxml2 libicu57 expat"

../docker-install.sh
