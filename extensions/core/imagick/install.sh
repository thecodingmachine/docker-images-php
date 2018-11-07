#!/usr/bin/env bash


export PECL_EXTENSION=amqp
export DEV_DEPENDENCIES="librabbitmq-dev"
export DEPENDENCIES="librabbitmq4"

../docker-install.sh
