#!/usr/bin/env php
<?php

if (!file_exists('/opt/container_started')) {
    passthru('php /usr/local/bin/generate_conf.php | sudo tee /etc/php/'.PHP_MAJOR_VERSION.'.'.PHP_MINOR_VERSION.'/mods-available/generated_conf.ini > /dev/null');
    passthru('php /usr/local/bin/setup_extensions.php | sudo bash');
}

require __DIR__.'/real_composer';
