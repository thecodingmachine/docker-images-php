<?php
/**
 * A very simple script in charge of generating the PHP configuration based on environment variables.
 * The script is run on each start of the container.
 */

$compiledExtensions = [
    'ftp', 'mysqlnd', 'mbstring'
];

$availableExtensions = [
    'ast', 'bcmath', 'bz2', 'calendar', 'dba', 'enchant', 'ev', 'event', 'exif', 'gd', 'gettext', 'gmp', 'imap', 'intl', 'ldap',
    'mcrypt', 'mysqli', 'opcache', 'pcntl', 'pdo_dblib', 'pdo_mysql', 'pdo_pgsql', 'pgsql', 'pspell',
    'shmop', 'snmp', 'soap', 'sockets', 'sysvmsg', 'sysvsem', 'sysvshm', 'tidy', 'wddx', 'xmlrpc', 'xsl', 'zip',
    'xdebug', 'amqp', 'igbinary', 'memcached', 'mongodb', 'redis', 'apcu', 'yaml', 'weakref'
];

$delimiter = [',', '|', ';', ':'];
$replace = str_replace($delimiter, ' ', getenv('PHP_EXTENSIONS'));
$phpExtensions = explode(' ', $replace);
$phpExtensions = array_map('trim', $phpExtensions);
$phpExtensions = array_map('strtolower', $phpExtensions);
$phpExtensions = array_filter($phpExtensions);

function enableExtension(string $extensionName): bool {
    global $phpExtensions;

    // If an extension name is set explicitly to "0" or "false" or "no", then it is not enabled.
    // This has priority
    $envName = 'PHP_EXTENSION_'.strtoupper($extensionName);

    $env = strtolower(trim(getenv($envName)));

    if ($env === '0' || $env === 'false' || $env === 'no' || $env === 'off') {
        return false;
    }

    if (in_array($extensionName, $phpExtensions, true)) {
        return true;
    }

    if ($env == '') {
        return false;
    }

    if ($env === '1' || $env === 'true' || $env === 'yes' || $env === 'on') {
        return true;
    }

    file_put_contents('php://stderr', 'Invalid environment variable value found for '.$envName.'. Value: "'.$env.'". Valid values are "0", "1", "yes", "no", "true", "false", "on", "off".'."\n");
    exit(1);
}

foreach ($compiledExtensions as $phpExtension) {
    $envName = 'PHP_EXTENSION_'.strtoupper($phpExtension);

    $env = strtolower(trim(getenv($envName)));

    if ($env === '0' || $env === 'false' || $env === 'no' || $env === 'off') {
        file_put_contents('php://stderr', "You cannot disable extension '$phpExtension'. It is compiled in the PHP binary.\n");
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

foreach ($availableExtensions as $extension) {
    if (enableExtension($extension)) {
        if ($extension === 'xdebug') {
            echo "zend_extension=xdebug.so\n";
            echo "xdebug.remote_host=".getenv('XDEBUG_REMOTE_HOST')."\n";
            echo "xdebug.remote_enable=on\n";
            //echo "xdebug.remote_autostart=off\n";
            //echo "xdebug.remote_port=9000\n";
            //echo "xdebug.remote_connect_back=0\n";
        } elseif ($extension === 'opcache') {
            echo "zend_extension=opcache.so\n";
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
        echo "$iniParam=$value\n";
    }
}

