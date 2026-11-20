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

function iniString(string $value): string
{
    return '"'.str_replace('"', '\\"', $value).'"';
}

$profiler = getProfiler();
$profilerDir = getenv('PHP_PROFILER_OUTPUT_DIR') ?: '/tmp/php-profiles';
$profilerTrigger = strtolower(getenv('PHP_PROFILER_TRIGGER') ?: 'request');
$profilerTriggerValue = (string) getenv('PHP_PROFILER_TRIGGER_VALUE');
if (!in_array($profilerTrigger, ['request', 'always', 'sample'], true)) {
    file_put_contents('php://stderr', 'Invalid value found for PHP_PROFILER_TRIGGER: "'.$profilerTrigger.'". Valid values are "request", "always", "sample".'."\n");
    exit(1);
}
// Xdebug and SPX do not create the folder of the profiles; every user of the container writes there
if ($profiler !== '' && !is_dir($profilerDir) && @mkdir($profilerDir, 0777, true)) {
    @chmod($profilerDir, 0777);
}

if (enableExtension('xdebug')) {
    $modes = [];
    if (enableExtension('xdebug', false)) {
        echo "xdebug.client_host=".xdebugClientHost()."\n";
        $modes[] = 'debug';
    }
    if ($profiler === 'xdebug') {
        if ($profilerTrigger === 'sample') {
            file_put_contents('php://stderr', "PHP_PROFILER_TRIGGER=sample is not supported by Xdebug: use excimer or xhprof.\n");
            exit(1);
        }
        $modes[] = 'profile';
        echo 'xdebug.start_with_request='.($profilerTrigger === 'always' ? 'yes' : 'trigger')."\n";
        echo 'xdebug.output_dir='.iniString($profilerDir)."\n";
        echo "xdebug.profiler_output_name=cachegrind.out.%t-%p\n";
        // Uncompressed: read by KCachegrind and by AI agents as is
        echo "xdebug.use_compression=0\n";
        if ($profilerTriggerValue !== '') {
            echo 'xdebug.trigger_value='.iniString($profilerTriggerValue)."\n";
        }
    }
    echo 'xdebug.mode='.implode(',', $modes)."\n";
}
if ($profiler === 'excimer' || $profiler === 'xhprof') {
    // Read by php-profiler.php with get_cfg_var()
    echo "auto_prepend_file=/usr/local/lib/thecodingmachine-php/php-profiler.php\n";
    $settings = [
        'name' => $profiler,
        'output_dir' => $profilerDir,
        'trigger' => $profilerTrigger,
        'trigger_value' => $profilerTriggerValue,
        'sample_rate' => getenv('PHP_PROFILER_SAMPLE_RATE') ?: '0.01',
        'excimer_period' => getenv('PHP_PROFILER_EXCIMER_PERIOD') ?: '0.001',
        'prepend' => (string) getenv('PHP_INI_AUTO_PREPEND_FILE'),
    ];
    foreach ($settings as $name => $value) {
        echo "thecodingmachine.profiler.$name=".iniString($value)."\n";
    }
}
if ($profiler === 'spx') {
    echo "spx.http_enabled=1\n";
    echo 'spx.http_key='.iniString(getenv('PHP_PROFILER_SPX_KEY') ?: 'dev')."\n";
    echo "spx.http_ip_whitelist=\"*\"\n";
    echo 'spx.data_dir='.iniString($profilerDir.'/spx')."\n";
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
    // With excimer or xhprof, the prepended file of the profiler runs this one
    if ($key === 'PHP_INI_AUTO_PREPEND_FILE' && ($profiler === 'excimer' || $profiler === 'xhprof')) {
        continue;
    }
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
