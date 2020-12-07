<?php
/**
 * A very simple script in charge of generating the PHP configuration based on environment variables.
 * The script is run on each start of the container.
 */

require __DIR__.'/utils.php';

// Reading environment variables from $_SERVER (because $_ENV is not necessarily populated, depending on variables_order directive):

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

if (enableExtension('xdebug')) {
    //echo "zend_extension=xdebug.so\n";
    echo "xdebug.client_host=".getenv('XDEBUG_CLIENT_HOST')."\n";
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
