#!/usr/bin/env bash

set -e
export EXTENSION=imap
export DEV_DEPENDENCIES="libc-client-dev libkrb5-dev"
export DEPENDENCIES="libgssapi-krb5-2 libgssrpc4 libk5crypto3 libkadm5clnt-mit11 libkadm5srv-mit11 libkrb5-3 libcomerr2 libc-client2007e libpam0g libssl1.1"
export CONFIGURE_OPTIONS="--with-imap --with-kerberos --with-imap-ssl"

../docker-install.sh
