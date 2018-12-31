#!/usr/bin/env bash

set -e
set -ex

# Install Blackfire
version=$(php -r "echo PHP_MAJOR_VERSION.PHP_MINOR_VERSION;")
curl -A "Docker" -o /tmp/blackfire-probe.tar.gz -D - -L -s https://blackfire.io/api/v1/releases/probe/php/linux/amd64/$version
mkdir -p /tmp/blackfire
tar zxpf /tmp/blackfire-probe.tar.gz -C /tmp/blackfire
mv /tmp/blackfire/blackfire-*.so $(php -r "echo ini_get('extension_dir');")/blackfire.so
rm -rf /tmp/blackfire /tmp/blackfire-probe.tar.gz

# Install Blackfire CLI tool
mkdir -p /tmp/blackfire
curl -A "Docker" -L https://blackfire.io/api/v1/releases/client/linux_static/amd64 | tar zxp -C /tmp/blackfire
mv /tmp/blackfire/blackfire /usr/bin/blackfire
rm -Rf /tmp/blackfire
