<?php
/**
 * A very simple script in charge of generating the CRON configuration based on environment variables.
 * The script is run on each start of the container.
 */

echo "# m h  dom mon dow   command\n";

foreach ($_SERVER as $key => $command) {
    if (strpos($key, 'CRON_COMMAND') === 0) {
        $suffix = substr($key, 12);

        $schedule = getenv('CRON_SCHEDULE'.$suffix);
        if (empty($schedule)) {
            error_log('Environment variable "CRON_SCHEDULE'.$suffix.'" is missing.');
            exit(1);
        }

        $user = getenv('CRON_USER'.$suffix);

        echo $schedule.' ';
        if ($user) {
            echo '/command/s6-setuidgid '.escapeshellarg($user).' ';
        }
        echo ' bash -c '.escapeshellarg($command).PHP_EOL;

    }
}

if (!file_exists('/usr/local/bin/supercronic')) {
    // Let's check Supercronic is installed (it could be not installed is we are using the slim version...)
    error_log('Cron is not available in this image. If you are using the thecodingmachine/php "slim" variant, do not forget to add "ARG INSTALL_CRON=1" in your Dockerfile. Check the documentation for more details.');
    exit(1);
}
