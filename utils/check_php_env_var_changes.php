<?php

$phpEnvVarCache = include '/opt/php_env_var_cache.php';

$envVars = getenv();

var_dump($envVars);
var_dump($phpEnvVarCache);

$shouldGenerateConfig = false;
$phpEnvVar = [];

foreach($envVars as $key => $value) {
    if (substr($key, 0, strlen('PHP_')) === 'PHP_') {
        if (!isset($phpEnvVarCache[$key])) {
            // The env var does not exist in the cache.
            $shouldGenerateConfig = true;
        } else if ($phpEnvVarCache[$key] !== $value) {
            // The value has changed.
            $shouldGenerateConfig = true;
        }

        $phpEnvVar[$key] = $value;
    }
}

if ($shouldGenerateConfig === false) {
    echo "0";
    exit(0);
}

$cacheFileContent = '<?php' . PHP_EOL . 'return ' . var_export($phpEnvVar, true) . ';' ;
$result = file_put_contents('/opt/php_env_var_cache.php', $cacheFileContent);
if ($result === false) {
    exit(1);
}

echo "1";
exit(0);