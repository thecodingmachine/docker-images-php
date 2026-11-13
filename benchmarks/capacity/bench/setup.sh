#!/usr/bin/env bash
# Installs the application, generates its data, the TLS certificate and the netem image.
set -e
P=$(cd "$(dirname "$0")/.." && pwd)
docker run --rm -v "$P:/bench" -w /bench/app -e COMPOSER_HOME=/tmp/composer \
  thecodingmachine/php:8.4-v5-cli bash -c '
    composer install -q --no-dev --classmap-authoritative --no-scripts &&
    php /bench/bench/generate-data.php /bench/app &&
    APP_ENV=prod APP_DEBUG=0 php bin/console cache:warmup -q && chmod -R a+rwX var'
mkdir -p "$P/run/certs"
[ -f "$P/run/certs/cert.pem" ] || openssl req -x509 -newkey ec -pkeyopt ec_paramgen_curve:P-256 -nodes -days 365 \
  -subj /CN=bench -keyout "$P/run/certs/key.pem" -out "$P/run/certs/cert.pem" 2>/dev/null
chmod 644 "$P/run/certs/"*.pem
docker build -q -t bench-netem -f "$P/bench/netem.Dockerfile" "$P/bench" > /dev/null
