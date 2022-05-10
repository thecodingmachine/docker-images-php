#!/usr/bin/env bash

set -e
set -ex

export BLACKFIRE_INSTALL_METHOD="raw"
bash -c "$(curl -L https://installer.blackfire.io/installer.sh)"
blackfire php:install
