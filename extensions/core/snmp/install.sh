#!/usr/bin/env bash

set -e
if [[ "${TARGETARCH}" == "arm64" ]]; then
  # 109 seconds to execute onto arm64 arch
  >&2 echo "php-snmp is not included with arm64 version (because build time is too long)"
  exit 0;
fi
export EXTENSION=snmp
#export DEV_DEPENDENCIES="libsnmp-dev libssl-dev"
#export DEPENDENCIES="snmp libsnmp30 libc6 libpci3 libsensors4 libwrap0 procps libssl1.1"
export DEPENDENCIES="snmpd snmp libsnmp-dev snmp-mibs-downloader"

../docker-install.sh

#chmod 700 /var/lib/snmp/mib_indexes
