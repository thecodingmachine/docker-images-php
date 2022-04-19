<?php

define('EXTENSIONS_INSTALL_DIR', '/usr/local/lib/thecodingmachine-php/extensions/current/');


/**
 * Returns the list of compiled and available extensions as .so files.
 *
 * @return string[]
 */
function getAvailableExtensions(): array
{
    return array_map(function(string $fileName) { return basename($fileName);}, glob('/var/lib/php/modules/'.getenv('PHP_VERSION').'/registry/*'));
}

/**
 * Returns the list of extensions that can be compiled
 *
 * @return string[]
 */
function getCompilableExtensions(): array
{
    return array_map('basename', glob(EXTENSIONS_INSTALL_DIR.'*', GLOB_ONLYDIR));
}

/**
 * Returns the list of extensions to enable based on the PHP_EXTENSIONS env variable
 *
 * @return array<int, string>
 */
function getExtensions(): array
{
    // Note: we cannot check the PHP_EXTENSION_XXX variables because it would create ~60 ONBUILD ARG PHP_EXTENSION_XXX lines
    // that create too many layers.
    //$toCheckExtensions = array_merge(getDeclaredEnvVars(), getPhpExtensionsEnvVar());
    //return array_filter($toCheckExtensions, 'enableExtension');
    return array_filter(getPhpExtensionsEnvVar(), 'enableExtension');
}

/**
 * Returns a list of extensions available in PHP_EXTENSION_XXX env variables.
 *
 * @return array<int, string>
 */
function getDeclaredEnvVars(): array
{
    $array = [];
    foreach ($_SERVER as $key => $value) {
        if (strpos($key, 'PHP_EXTENSION_') === 0) {
            $array[] = strtolower(substr($key, 14));
        }
    }
    return $array;
}

/**
 * Returns a list of extensions available in the PHP_EXTENSIONS environment variable
 *
 * @return array<int, string>
 */
function getPhpExtensionsEnvVar(): array
{
    static $phpExtensions = null;
    if ($phpExtensions !== null) {
        return $phpExtensions;
    }
    $delimiter = [',', '|', ';', ':'];
    $replace = str_replace($delimiter, ' ', getenv('PHP_EXTENSIONS'));
    $phpExtensions = explode(' ', $replace);
    $phpExtensions = array_map('trim', $phpExtensions);
    $phpExtensions = array_map('strtolower', $phpExtensions);
    $phpExtensions = array_filter($phpExtensions);
    return $phpExtensions;
}

function getPhpVersionEnvVar()
{
    static $phpVersion = null;
    if ($phpVersion !== null) {
        return $phpVersion;
    }

    $phpVersion = getenv('PHP_VERSION');

    return $phpVersion;
}


function enableExtension(string $extensionName): bool {
    $phpExtensions = getPhpExtensionsEnvVar();

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
