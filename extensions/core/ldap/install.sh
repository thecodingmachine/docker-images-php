#!/usr/bin/env bash

set -ex

apt-get install -y --no-install-recommends libldap2-dev libldap-2.4-2
#ln -s /usr/lib/x86_64-linux-gnu/libldap_r.so /usr/lib/libldap.so
#ln -s /usr/lib/x86_64-linux-gnu/libldap_r.a /usr/lib/libldap_r.a

docker-php-ext-install ldap

apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false -o APT::AutoRemove::SuggestsImportant=false libldap2-dev
