#!/usr/bin/env bash

set -e
export PECL_EXTENSION=imagick
export DEV_DEPENDENCIES="libmagickwand-dev libmagickcore-dev"
export DEPENDENCIES="imagemagick-6-common libmagickcore-6.q16-3 libmagickwand-6.q16-3 imagemagick-6-common gsfonts libmagickcore-6.q16-3-extra ghostscript ttf-dejavu-core"

../docker-install.sh
