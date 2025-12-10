#!/usr/bin/env bash

set -e
export DEV_DEPENDENCIES="librdkafka-dev"
export DEPENDENCIES="librdkafka1"
PECL_EXTENSION=rdkafka ../docker-install.sh
