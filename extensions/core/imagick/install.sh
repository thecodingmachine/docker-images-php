#!/usr/bin/env bash


export PECL_EXTENSION=imagick
export DEV_DEPENDENCIES="libmagickcore-6.q16-3 libmagickwand-6.q16-3"
export DEPENDENCIES="imagemagick-6-common libfftw3-double3 libfontconfig1 libfreetype6 libgomp1 libjbig0 libjpeg62-turbo liblcms2-2 liblqr-1-0 libltdl7 liblzma5 libopenjp2-7 libpng16-16 libtiff5 libx11-6 libxext6 libxml2 zlib1g gsfonts libmagickcore-6.q16-3-extra ghostscript ttf-dejavu-core"

../docker-install.sh
