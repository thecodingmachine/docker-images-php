#!/usr/bin/php
<?php
/**
 * A very simple script in charge of generating the PHP configuration based on environment variables.
 * The script is run on each start of the container.
 */

require __DIR__.'/utils.php';

$compiledExtensions = [
    /*'ftp', 'mysqlnd', 'mbstring'*/
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

$toDisable = [];
$toEnable = [];

foreach ($availableExtensions as $extension) {
    if (enableExtension($extension)) {
        $toEnable[$extension] = $extension;
    } else {
        $toDisable[$extension] = $extension;
    }
}

// mysqlnd is a dependency required for mysqli or pdo_mysql
if (enableExtension('mysqli') || enableExtension('pdo_mysql')) {
    $toEnable['mysqlnd'] = 'mysqlnd';
    unset($toDisable['mysqlnd']);
}

if ($toDisable) {
    echo 'phpdismod '.implode(' ', $toDisable)."\n";
}
if ($toEnable) {
    echo 'phpenmod '.implode(' ', $toEnable)."\n";
}
