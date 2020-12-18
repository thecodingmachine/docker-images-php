ARG BRANCH
ARG BRANCH_VARIANT
ARG PHP_VERSION

ARG PHP_EXTENSIONS="gd"
FROM thecodingmachine/php:${PHP_VERSION}-${BRANCH}-slim-${BRANCH_VARIANT}

COPY composer.json composer.json

RUN php -m

RUN which php

RUN sudo tee "/etc/php/${PHP_VERSION}/mods-available/generated_conf.ini"

# Let's check that GD is available.
RUN composer install
