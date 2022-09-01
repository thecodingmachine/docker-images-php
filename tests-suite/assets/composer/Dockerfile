ARG BRANCH
ARG BRANCH_VARIANT
ARG PHP_VERSION

FROM thecodingmachine/php:${PHP_VERSION}-${BRANCH}-${BRANCH_VARIANT}

ENV PHP_EXTENSION_GD=1

COPY composer.json composer.json

# Let's check that GD is available.
RUN composer install
