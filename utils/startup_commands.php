<?php
/**
 * A very simple script in charge of generating the startup commands based on environment variables.
 * The script is run on each start of the container.
 */

$commands = array_filter($_SERVER, function(string $key) {
    return strpos($key, 'STARTUP_COMMAND') === 0;
}, ARRAY_FILTER_USE_KEY);

ksort($commands);

echo "set -e\n";


// Let's run the commands as user $UID if env variable UID is set.

foreach ($commands as $command) {
    $line = $command;
    if (isset($_SERVER['UID'])) {
        $line = 'sudo -E -u \\#'.$_SERVER['UID'].' bash -c '.escapeshellarg($line);
    }
    echo $line."\n";
}
