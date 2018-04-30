<?php
/**
 * A very simple script in charge of generating the CRON configuration based on environment variables.
 * The script is run on each start of the container.
 */

$tiniPid = $argv[1];

foreach ($_SERVER as $key => $command) {
    if (strpos($key, 'CRON_COMMAND') === 0) {
        $suffix = substr($key, 12);

        $schedule = getenv('CRON_SCHEDULE'.$suffix);
        if (empty($schedule)) {
            error_log('Environment variable "CRON_SCHEDULE'.$suffix.'" is missing.');
            exit(1);
        }

        $user = getenv('CRON_USER'.$suffix) ?: 'root';

        // Note: this is a bit cryptic so here is what is going on:
        // First the command is piped into "sed" and we add [Cron]
        // In case there is an error message (on stderr), this will not be handled by sed.
        // So we switch output and error streams using "3>&2 2>&1 1>&3"
        // And we apply again sed on stdout (which is the past stderr)
        // Finally we switch back to stderr and stdout: 4>&2 2>&1 1>&4
        // and we put the output in /proc/xxx/fd1|2 which are the processes output for the Docker container.
        echo $schedule.' '.$user.' (((('.$command.") | sed -e 's/^/[Cron] /' ) 3>&2 2>&1 1>&3 | sed -e 's/^/[Cron error] /') 4>&2 2>&1 1>&4) > /proc/$tiniPid/fd/1 2> /proc/$tiniPid/fd/2\n";
    }
}
