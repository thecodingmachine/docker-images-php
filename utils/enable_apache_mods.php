<?php
/**
 * Enables or disables Apache extensions based on environment variables set.
 */

$defaultExtensions = ['access_compat', 'alias', 'auth_basic', 'authn_core', 'authn_file', 'authz_core', 'authz_host', 'authz_user', 'autoindex', 'deflate', 'dir', 'env', 'expires', 'filter', 'mime', 'mpm_prefork', 'negotiation', 'php'.getenv('PHP_VERSION'), 'reqtimeout', 'rewrite', 'setenvif', 'status'];

$availableExtensions = ['access_compat', 'actions', 'alias', 'allowmethods', 'asis', 'auth_basic', 'auth_digest', 'auth_form', 'authn_anon', 'authn_core', 'authn_dbd', 'authn_dbm', 'authn_file', 'authn_socache', 'authnz_fcgi', 'authnz_ldap', 'authz_core', 'authz_dbd', 'authz_dbm', 'authz_groupfile', 'authz_host', 'authz_owner', 'authz_user', 'autoindex', 'buffer', 'cache', 'cache_disk', 'cache_socache', 'cgi', 'cgid', 'charset_lite', 'data', 'dav', 'dav_fs', 'dav_lock', 'dbd', 'deflate', 'dialup', 'dir', 'dump_io', 'echo', 'env', 'ext_filter', 'expires', 'file_cache', 'filter', 'headers', 'heartbeat', 'heartmonitor', 'ident', 'include', 'info', 'lbmethod_bybusyness', 'lbmethod_byrequests', 'lbmethod_bytraffic', 'lbmethod_heartbeat', 'ldap', 'log_debug', 'log_forensic', 'lua', 'macro', 'mime', 'mime_magic', 'mpm_event', 'mpm_prefork', 'mpm_worker', 'negotiation', 'php'.getenv('PHP_VERSION'), 'proxy', 'proxy_ajp', 'proxy_balancer', 'proxy_connect', 'proxy_express', 'proxy_fcgi', 'proxy_fdpass', 'proxy_ftp', 'proxy_html', 'proxy_http', 'proxy_scgi', 'proxy_wstunnel', 'ratelimit', 'reflector', 'remoteip', 'reqtimeout', 'request', 'rewrite', 'sed', 'session', 'session_cookie', 'session_crypto', 'session_dbd', 'setenvif', 'slotmem_plain', 'slotmem_shm', 'socache_dbm', 'socache_memcache', 'socache_shmcb', 'speling', 'ssl', 'status', 'substitute', 'suexec', 'unique_id', 'userdir', 'usertrack', 'vhost_alias', 'xml2enc'];

$delimiter = [',', '|', ';', ':'];
$replace = str_replace($delimiter, ' ', getenv('APACHE_EXTENSIONS'));
$apacheExtensions = explode(' ', $replace);
$apacheExtensions = array_map('trim', $apacheExtensions);
$apacheExtensions = array_map('strtolower', $apacheExtensions);
$apacheExtensions = array_filter($apacheExtensions);

function enableExtension(string $extensionName): bool {
    global $apacheExtensions, $defaultExtensions;

    // If an extension name is set explicitly to "0" or "false" or "no", then it is not enabled.
    // This has priority
    $envName = 'APACHE_EXTENSION_'.strtoupper($extensionName);

    $env = strtolower(trim(getenv($envName)));

    if ($env === '0' || $env === 'false' || $env === 'no' || $env === 'off') {
        return false;
    }

    if (in_array($extensionName, $apacheExtensions, true)) {
        return true;
    }

    if ($env === '1' || $env === 'true' || $env === 'yes' || $env === 'on') {
        return true;
    }

    if (in_array($extensionName, $defaultExtensions, true)) {
        return true;
    }

    if ($env == '') {
        return false;
    }

    file_put_contents('php://stderr', 'Invalid environment variable value found for '.$envName.'. Value: "'.$env.'". Valid values are "0", "1", "yes", "no", "true", "false", "on", "off".'."\n");
    exit(1);
}

// Validate the content of PHP_EXTENSIONS
foreach ($apacheExtensions as $apacheExtension) {
    if (!in_array($apacheExtension, $availableExtensions, true)) {
        file_put_contents('php://stderr', "Invalid extension name found in APACHE_EXTENSIONS environment variable. Found: '$apacheExtension'. Available extensions: ".implode(', ', $availableExtensions).".\n");
        exit(1);
    }
}

$toEnableExtensions = '';
$toDisableExtensions = '';

foreach ($availableExtensions as $extension) {
    if (enableExtension($extension)) {
        $toEnableExtensions .= $extension.' ';
    } else {
        $toDisableExtensions .= $extension.' ';
    }
}

echo 'a2enmod '.$toEnableExtensions.' > /dev/null && ';
echo 'a2dismod '.$toDisableExtensions." > /dev/null\n";
