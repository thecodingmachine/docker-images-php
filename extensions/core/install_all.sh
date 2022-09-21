#!/usr/bin/env bash

set -e
set +x

# Let's disable autoclean of package list after apt-get install
mv /etc/apt/apt.conf.d/docker-clean /tmp/docker-clean

apt-get update

mkdir -p /var/log/ext-php/

for ext in */; do \
    cd $ext
    ext_no_slash=${ext%/}
    echo "***************** Installing $ext_no_slash ******************"
    LOG="/var/log/ext-php/install-${ext_no_slash}"
    start=$(date +%s)
    ./install.sh 2>&1 | tee -a "${LOG}.log"
    end=$(date +%s)
    echo "$(($end-$start)) seconds to execute ${ext_no_slash}" > "${LOG}.time"
    cd ..
done

# Let's enable autoclean again
mv /tmp/docker-clean /etc/apt/apt.conf.d/docker-clean

apt-get purge -y php-pear build-essential php${PHP_VERSION}-dev pkg-config
apt-get autoremove -y
apt-get clean
rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /usr/share/doc/*
rm -f /usr/local/bin/pickle
