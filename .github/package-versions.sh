#!/usr/bin/env bash
# Prints the --set options of docker buildx bake giving the versions of the PHP (sury) and NodeJS (nodesource)
# packages of a bake group, for one arch: the layers that install them are rebuilt only when these versions change.
# The version of the PHP packages is also the label com.thecodingmachine.php.package of the images, read by php-watch.sh.
# PHP_PACKAGE_VERSION, when set, replaces the version read from sury.
# Usage: package-versions.sh <bake group> <arch>
set -euo pipefail

GROUP="$1"
ARCH="$2"

TARGETS=$(docker buildx bake --print --progress=quiet "${GROUP}")
PHP_VERSION=$(jq -r '[.target[].args.PHP_VERSION // empty] | unique | .[0]' <<< "${TARGETS}")

if [ -z "${PHP_PACKAGE_VERSION:-}" ]; then
  PHP_PACKAGE_VERSION=$(curl -fsS --retry 3 "https://packages.sury.org/php/dists/noble/main/binary-${ARCH}/Packages.gz" | gunzip \
    | awk -v p="php${PHP_VERSION}-cli" '$1 == "Package:" {match_ = ($2 == p)} match_ && $1 == "Version:" {print $2}' \
    | sort -V | tail -n 1)
fi
echo "--set=*.args.PHP_PACKAGE_VERSION=${PHP_PACKAGE_VERSION}"
echo "--set=*.labels.com.thecodingmachine.php.package=${PHP_PACKAGE_VERSION}"

for NODE_VERSION in $(jq -r '[.target[].args.NODE_VERSION // empty] | unique | .[]' <<< "${TARGETS}"); do
  NODE_PACKAGE_VERSION=$(curl -fsS --retry 3 "https://deb.nodesource.com/node_${NODE_VERSION}.x/dists/nodistro/main/binary-${ARCH}/Packages" \
    | awk '$1 == "Package:" {match_ = ($2 == "nodejs")} match_ && $1 == "Version:" {print $2}' \
    | sort -V | tail -n 1)
  echo "--set=*-node${NODE_VERSION}.args.NODE_PACKAGE_VERSION=${NODE_PACKAGE_VERSION}"
done
