#!/usr/bin/env bash

set -e
export EXTENSION=mysqlnd
export PACKAGE_NAME=mysql

../docker-install.sh

# Exception for this package that enables both mysqlnd and mysqli and pdo_mysql
phpdismod mysqli
phpdismod pdo_mysql
