#!/bin/bash

sudo chown docker:docker /opt/php_env_var_cache.php

REGENERATE=$(/usr/bin/real_php /usr/local/bin/check_php_env_var_changes.php)

if [[ "$REGENERATE" != "0" ]] && [[ "$REGENERATE" != "1" ]]; then
  exit 1
fi

if [[ "$REGENERATE" == "1" ]]; then
  /usr/bin/real_php /usr/local/bin/generate_conf.php | sudo tee "/etc/php/${PHP_VERSION}/mods-available/generated_conf.ini" > /dev/null
  /usr/bin/real_php /usr/local/bin/setup_extensions.php | sudo bash
fi

/usr/bin/real_php "$@"
