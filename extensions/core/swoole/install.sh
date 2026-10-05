#!/usr/bin/env bash


set -e
export EXTENSION=swoole

# swoole requires mysqlnd to be loaded (installed by pdo_mysql)
phpenmod -v $PHP_VERSION mysqlnd
../docker-install.sh
phpdismod -v $PHP_VERSION mysqlnd
