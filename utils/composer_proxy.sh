#!/usr/bin/env bash

set -euo pipefail

# We regenerate the configuration from environment variable, but only if the container is not started (i.e. if we are in a BUILD stage)
if [ ! -f /opt/container_started ]; then
    php /usr/local/bin/generate_conf.php | sudo tee /etc/php/${PHP_VERSION}/mods-available/generated_conf.ini > /dev/null
    php /usr/local/bin/setup_extensions.php | sudo bash
fi

real_composer "$@"
