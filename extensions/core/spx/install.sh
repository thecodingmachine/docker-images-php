#!/usr/bin/env bash

set -e
# SPX is not packaged by sury: built from its sources
SPX_VERSION=0.4.22

# zlib1g-dev may already be needed by another extension (libsnmp-dev)
ZLIB_DEV=$(dpkg-query -W -f '${Status}' zlib1g-dev 2> /dev/null || true)
apt install -y --no-install-recommends build-essential php${PHP_VERSION}-dev zlib1g-dev
curl -fsSL "https://github.com/NoiseByNorthwest/php-spx/archive/refs/tags/v${SPX_VERSION}.tar.gz" | tar xz -C /tmp
cd "/tmp/php-spx-${SPX_VERSION}"
phpize
./configure
make -j"$(nproc)"
make install
cd /
rm -rf "/tmp/php-spx-${SPX_VERSION}"
if [[ "${ZLIB_DEV}" != "install ok installed" ]]; then
    apt purge -y zlib1g-dev
fi
echo "extension=spx.so" > "/etc/php/${PHP_VERSION}/mods-available/spx.ini"
touch "/var/lib/php/modules/${PHP_VERSION}/registry/spx"

phpenmod -v "${PHP_VERSION}" spx
/usr/bin/real_php -m | grep -x SPX
[[ "$(/usr/bin/real_php -r "echo '';" 2>&1)" == "" ]]
phpdismod -v "${PHP_VERSION}" spx
