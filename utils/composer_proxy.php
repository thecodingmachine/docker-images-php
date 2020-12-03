#!/usr/bin/env php
<?php

// We regenerate the configuration from environment variable, but only if the container is not started (i.e. if we are in a BUILD stage)
if (!file_exists('/opt/container_started')) {
    passthru('php /usr/local/bin/generate_conf.php | sudo tee /etc/php/'.PHP_MAJOR_VERSION.'.'.PHP_MINOR_VERSION.'/mods-available/generated_conf.ini > /dev/null');
    passthru('php /usr/local/bin/setup_extensions.php | sudo bash');
}

array_shift($argv);

$args = array_map(function(string $item) { return escapeshellarg($item); }, $argv);

// Let's pass the command down to the real composer
passthru('real_composer '.implode(' ', $args), $exitCode);
exit($exitCode);
