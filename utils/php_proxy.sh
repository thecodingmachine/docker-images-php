#!/bin/bash

# Users that cannot use sudo run PHP with the current configuration
if ! sudo -n chown docker:docker /opt/php_env_var_cache.php 2> /dev/null; then
  exec /usr/bin/real_php "$@"
fi

REGENERATE=$(/usr/bin/real_php -d display_errors=stderr /usr/local/bin/check_php_env_var_changes.php)

if [[ "$REGENERATE" != "0" ]] && [[ "$REGENERATE" != "1" ]]; then
  >&2 echo "Unexpected PHP proxy output:"
  >&2 echo $REGENERATE
  exit 1
fi

if [[ "$REGENERATE" == "1" ]]; then
  /usr/bin/real_php -d display_errors=stderr /usr/local/bin/generate_conf.php | sudo tee "/etc/php/${PHP_VERSION}/mods-available/generated_conf.ini" > /dev/null
  PHP_VERSION="${PHP_VERSION}" /usr/bin/real_php -d display_errors=stderr /usr/local/bin/setup_extensions.php | sudo bash
fi

exec /usr/bin/real_php "$@"
