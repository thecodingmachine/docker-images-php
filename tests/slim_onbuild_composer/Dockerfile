ARG BRANCH
ARG BRANCH_VARIANT
ARG PHP_VERSION

ARG PHP_EXTENSIONS="gd"
FROM thecodingmachine/php:${PHP_VERSION}-${BRANCH}-slim-${BRANCH_VARIANT}

COPY composer.json composer.json

RUN env

RUN php -m

# Let's check that GD is available.
RUN composer install
