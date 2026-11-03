#!/bin/bash

source /usr/local/bin/php_env_fingerprint.sh

# The configuration is regenerated only when the PHP_* environment variables changed since its last generation
FINGERPRINT=$(php_env_fingerprint)
read -r GENERATED_FINGERPRINT < /opt/php_env_fingerprint
if [[ "$FINGERPRINT" == "$GENERATED_FINGERPRINT" ]]; then
  exec /usr/bin/real_php "$@"
fi

# Users that cannot use sudo run PHP with the current configuration
if ! sudo -n true 2> /dev/null; then
  exec /usr/bin/real_php "$@"
fi

/usr/bin/real_php -d display_errors=stderr /usr/local/bin/generate_conf.php | sudo tee "/etc/php/${PHP_VERSION}/mods-available/generated_conf.ini" > /dev/null
PHP_VERSION="${PHP_VERSION}" /usr/bin/real_php -d display_errors=stderr /usr/local/bin/setup_extensions.php | sudo bash
echo "$FINGERPRINT" | sudo tee /opt/php_env_fingerprint > /dev/null

exec /usr/bin/real_php "$@"
