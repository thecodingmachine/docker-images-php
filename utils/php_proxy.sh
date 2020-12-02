#!/bin/bash

# We regenerate the configuration from environment variable, but only if the container is not started (i.e. if we are in a BUILD stage or if overloading the entrypoint)
if [[ ! -f /opt/container_started  ]]; then
  /usr/bin/real_php /usr/local/bin/generate_conf.php | sudo tee "/etc/php/${PHP_VERSION}/mods-available/generated_conf.ini" > /dev/null
  /usr/bin/real_php /usr/local/bin/setup_extensions.php | sudo bash
  sudo touch /opt/container_started
fi

/usr/bin/real_php "$@"
