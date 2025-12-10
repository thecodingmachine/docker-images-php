#!/usr/bin/env bash

set -e
export EXTENSION=snmp
#export DEV_DEPENDENCIES="libsnmp-dev libssl-dev"
#export DEPENDENCIES="snmp libsnmp30 libc6 libpci3 libsensors4 libwrap0 procps libssl1.1"
export DEPENDENCIES="snmpd snmp libsnmp-dev snmp-mibs-downloader"

../docker-install.sh

#chmod 700 /var/lib/snmp/mib_indexes
