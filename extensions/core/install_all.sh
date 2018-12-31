#!/usr/bin/env bash

set -e
set -ex

apt-get update

for ext in */; do \
    cd $ext
    ext_no_slash=${ext%/}
    echo "***************** Installing $ext_no_slash ******************"
    ./install.sh
    cd ..
done
