<?php
/**
 * A very simple script in charge of generating the PHP configuration based on environment variables.
 * The script is run on each start of the container.
 */

require __DIR__.'/utils.php';

/**
 * XDEBUG_CLIENT_HOST, else host.docker.internal when it resolves to a non-loopback address (Docker Desktop, OrbStack,
 * extra_hosts: host-gateway), else the default gateway of the container (Docker Engine on Linux).
 */
function xdebugClientHost(): string
{
    $host = getenv('XDEBUG_CLIENT_HOST');
    if ($host) {
        return $host;
    }
    $address = gethostbyname('host.docker.internal');
    if ($address !== 'host.docker.internal' && strpos($address, '127.') !== 0) {
        return $address;
    }
    // xdebug://gateway needs Xdebug 3.2, which does not support PHP 7.4
    if (PHP_VERSION_ID >= 80000) {
        return 'xdebug://gateway';
    }
    foreach (file('/proc/net/route') ?: [] as $line) {
        $fields = preg_split('/\s+/', trim($line));
        if (($fields[1] ?? '') === '00000000' && isset($fields[2])) {
            return long2ip(hexdec(implode('', array_reverse(str_split($fields[2], 2)))));
        }
    }
    return '';
}

// Reading environment variables from $_SERVER (because $_ENV is not necessarily populated, depending on variables_order directive):

if (enableExtension('xdebug')) {
    //echo "zend_extension=xdebug.so\n";
    echo "xdebug.client_host=".xdebugClientHost()."\n";
    echo "xdebug.mode=debug\n";
    //echo "xdebug.remote_autostart=off\n";
    //echo "xdebug.remote_port=9000\n";
    //echo "xdebug.remote_connect_back=0\n";
}
if (enableExtension('blackfire')) {
    $blackFireAgent = getenv('BLACKFIRE_AGENT');
    if (!$blackFireAgent) {
        $blackFireAgent = 'blackfire';
    }
    //echo "extension=blackfire.so\n";
    echo "blackfire.agent_socket=tcp://$blackFireAgent:8707\n";
}

foreach ($_SERVER as $key => $value) {
    if (strpos($key, 'PHP_INI_') === 0) {
        $iniParam = substr($key, 8);
        if ($iniParam !== 'SMTP') {
            // SMTP is the only php.ini parameter that contains uppercase letters (!)
            $iniParam = strtolower($iniParam);
        }
        $iniParam = str_replace('__', '.', $iniParam);
        // Let's protect the value if this is a string.
        if (!is_numeric($value) && $iniParam !== 'error_reporting') {
            $value = '"'.str_replace('"', '\\"', $value).'"';
        }
        echo "$iniParam=$value\n";
    }
}
