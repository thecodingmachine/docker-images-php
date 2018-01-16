<?php
/**
 * A very simple script in charge of generating the CRON configuration based on environment variables.
 * The script is run on each start of the container.
 */

foreach ($_SERVER as $key => $command) {
    if (strpos($key, 'CRON_COMMAND') === 0) {
        $suffix = substr($key, 12);

        $schedule = getenv('CRON_SCHEDULE'.$suffix);
        if (empty($schedule)) {
            error_log('Environment variable "CRON_SCHEDULE'.$suffix.'" is missing.');
            exit(1);
        }

        $user = getenv('CRON_USER'.$suffix) ?: 'root';

        echo $schedule.' '.$user.' ('.$command.") | sed -e 's/^/[Cron] /' > /proc/1/fd/1 2>/proc/1/fd/2\n";
    }
}
