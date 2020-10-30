<?php
/**
 * A very simple script in charge of generating the DMA configuration based on environment variables.
 * The script is run on each start of the container.
 */

require __DIR__.'/utils.php';

$found = false;

foreach ($_SERVER as $key => $value) {
    if (strpos($key, 'DMA_') === 0) {
        $found = true;
    }
    if (strpos($key, 'DMA_CONF_') === 0) {
        $suffix = substr($key, 9);

        echo $suffix." ".$value."\n";
    }
}

if (($found === true) && !file_exists('/usr/sbin/dma')) {
    // Let's check DMA is installed (it could be not installed is we are using the slim version...)
    error_log('DMA is not available in this image. If you are using the thecodingmachine/php "slim" variant, do not forget to add "ARG INSTALL_DMA=1" in your Dockerfile. Check the documentation for more details.');
    exit(1);
}
