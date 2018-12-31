#!/usr/bin/env bash

set -e
export PECL_EXTENSION=yaml
export DEV_DEPENDENCIES="libyaml-dev"
export DEPENDENCIES="libyaml-0-2"


../docker-install.sh
