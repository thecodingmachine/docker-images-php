<?php
/**
 * A very simple script in charge of generating the PHP configuration based on environment variables.
 * The script is run on each start of the container.
 */

require 'utils.php';

$compiledExtensions = [
    'ftp', 'mysqlnd', 'mbstring'
];

$availableExtensions = getAvailableExtensions();

$phpExtensions = getPhpExtensionsEnvVar();

foreach ($compiledExtensions as $phpExtension) {
    $envName = 'PHP_EXTENSION_'.strtoupper($phpExtension);

    $env = strtolower(trim(getenv($envName)));

    if ($env === '0' || $env === 'false' || $env === 'no' || $env === 'off') {
        file_put_contents('php://stderr', "You cannot disable extension '$phpExtension'. It is compiled in the PHP binary.\n");
        exit(1);
    }
    if (enableExtension($phpExtension)) {
        file_put_contents('php://stderr', "You cannot explicitly enable extension '$phpExtension'. It is compiled in the PHP binary and therefore always available.\n");
        exit(1);
    }
}

// Validate the content of PHP_EXTENSIONS
foreach ($phpExtensions as $phpExtension) {
    if (!in_array($phpExtension, $availableExtensions, true)) {
        file_put_contents('php://stderr', "Invalid extension name found in PHP_EXTENSIONS environment variable. Found: '$phpExtension'. Available extensions: ".implode(', ', $availableExtensions).".\n");
        exit(1);
    }
}

if (enableExtension('xdebug') && enableExtension('blackfire')) {
    error_log('WARNING: Both Blackfire and Xdebug are enabled. This is not recommended as the PHP engine may not behave as expected. You should strongly consider disabling Xdebug or Blackfire.');
}

foreach ($availableExtensions as $extension) {
    if (enableExtension($extension)) {
        if ($extension === 'xdebug') {
            echo "zend_extension=xdebug.so\n";
            echo "xdebug.remote_host=".getenv('XDEBUG_REMOTE_HOST')."\n";
            echo "xdebug.remote_enable=on\n";
            //echo "xdebug.remote_autostart=off\n";
            //echo "xdebug.remote_port=9000\n";
            //echo "xdebug.remote_connect_back=0\n";
        } elseif ($extension === 'blackfire') {
            $blackFireAgent = getenv('BLACKFIRE_AGENT');
            if (!$blackFireAgent) {
                $blackFireAgent = 'blackfire';
            }
            echo "extension=blackfire.so\n";
            echo "blackfire.agent_socket=tcp://$blackFireAgent:8707\n";
        } elseif ($extension === 'opcache') {
            echo "zend_extension=opcache.so\n";
        } elseif ($extension === 'event' && !enableExtension('sockets')) {
            // Event extension depends on Sockets extension
            echo "extension=sockets.so\n";
            echo "extension=event.so\n";
        } else {
            echo "extension=$extension.so\n";
        }
    }
}

// Reading environment variables from $_SERVER (because $_ENV is not necessarily populated, depending on variables_order directive):

foreach ($_SERVER as $key => $value) {
    if (strpos($key, 'PHP_INI_') === 0) {
        $iniParam = strtolower(substr($key, 8));
        $iniParam = str_replace('__', '.', $iniParam);
        // Let's protect the value if this is a string.
        if (!is_numeric($value) && $iniParam !== 'error_reporting') {
            $value = '"'.str_replace('"', '\\"', $value).'"';
        }
        echo "$iniParam=$value\n";
    }
}
