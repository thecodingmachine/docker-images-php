#!/usr/bin/env bash

export EXTENSION=xsl
export DEV_DEPENDENCIES="libxml2-dev libxslt1-dev"
export DEPENDENCIES="libxml2 libicu57 libxslt1.1"

../docker-install.sh
