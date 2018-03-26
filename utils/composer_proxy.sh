#!/usr/bin/env bash

set -euo pipefail

php /usr/local/bin/generate_conf.php | sudo tee /usr/local/etc/php/conf.d/generated_conf.ini > /dev/null

real_composer "$@"
