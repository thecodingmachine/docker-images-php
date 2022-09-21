<?php
/**
 * A very simple script in charge of generating the CRON configuration based on environment variables.
 * The script is run on each start of the container.
 */

$found = false;

foreach ($_SERVER as $key => $command) {
    if (strpos($key, 'CRON_COMMAND') === 0) {
        $found = true;
        $suffix = substr($key, 12);

        $schedule = getenv('CRON_SCHEDULE'.$suffix);
        if (empty($schedule)) {
            error_log('Environment variable "CRON_SCHEDULE'.$suffix.'" is missing.');
            exit(1);
        }

        $user = getenv('CRON_USER'.$suffix);

        if ($user) {
            echo $schedule." sudo -E -u $user -- bash -c ".escapeshellarg($command)."\n";
        } else {
            echo $schedule.' '.$command."\n";
        }

    }
}

if (($found === true) && !file_exists('/usr/local/bin/supercronic')) {
    // Let's check Supercronic is installed (it could be not installed is we are using the slim version...)
    error_log('Cron is not available in this image. If you are using the thecodingmachine/php "slim" variant, do not forget to add "ARG INSTALL_CRON=1" in your Dockerfile. Check the documentation for more details.');
    exit(1);
}
