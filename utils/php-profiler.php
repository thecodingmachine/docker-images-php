<?php
/**
 * Prepended to every script when PHP_PROFILER is excimer or xhprof: profiles the requests and the commands that carry
 * the trigger, then writes the profile and a text summary to PHP_PROFILER_OUTPUT_DIR.
 * Its settings are the thecodingmachine.profiler.* entries written by generate_conf.php.
 */

$thecodingmachineProfilerPrepend = (static function (): string {
    $setting = static function (string $name, string $default = ''): string {
        $value = get_cfg_var('thecodingmachine.profiler.'.$name);
        return $value === false || $value === '' ? $default : (string) $value;
    };

    $expected = $setting('trigger_value');
    $carries = static function ($value) use ($expected): bool {
        if ($value === null || $value === false || $value === '' || $value === '0') {
            return false;
        }
        return $expected === '' || hash_equals($expected, (string) $value);
    };
    switch ($setting('trigger', 'request')) {
        case 'always':
            $profile = true;
            break;
        case 'sample':
            $profile = mt_rand() / mt_getrandmax() < (float) $setting('sample_rate', '0.01');
            break;
        default:
            $profile = PHP_SAPI === 'cli'
                ? $carries(getenv('PHP_PROFILE'))
                : $carries($_SERVER['HTTP_X_PHP_PROFILE'] ?? $_COOKIE['PHP_PROFILE'] ?? $_GET['PHP_PROFILE'] ?? null);
    }

    // GET /checkout?page=2 or console app:import, then the duration, the peak memory and the profiler
    $header = static function (float $milliseconds, string $profiler): string {
        $what = PHP_SAPI === 'cli'
            ? implode(' ', $_SERVER['argv'] ?? [])
            : ($_SERVER['REQUEST_METHOD'] ?? 'GET').' '.($_SERVER['REQUEST_URI'] ?? '/');
        return sprintf("%s\n%.0f ms, peak memory %.1f MB, %s\n\n", $what, $milliseconds, memory_get_peak_usage(true) / 1048576, $profiler);
    };

    // The PHP scripts of the image that configure the container at startup
    $script = (string) ($_SERVER['SCRIPT_FILENAME'] ?? '');
    if (dirname($script) === '/usr/local/bin' && substr($script, -4) === '.php') {
        $profile = false;
    }

    $profiler = $setting('name');
    if ($profile && $profiler === 'excimer' && class_exists('ExcimerProfiler')) {
        $excimer = new ExcimerProfiler();
        $period = (float) $setting('excimer_period', '0.001');
        $excimer->setPeriod($period);
        $excimer->setEventType(EXCIMER_REAL);
        $excimer->start();
        $stop = static function () use ($excimer, $period, $header): array {
            $excimer->stop();
            $log = $excimer->getLog();
            // The 30 functions where the most samples were taken
            $samples = $log->getEventCount();
            $functions = $log->aggregateByFunction();
            uasort($functions, static function (array $a, array $b): int {
                return $b['self'] <=> $a['self'];
            });
            $summary = $header($samples * $period * 1000, sprintf('Excimer, %d samples every %.1f ms', $samples, $period * 1000));
            $summary .= sprintf("%7s %7s  %s\n", 'self %', 'incl %', 'function');
            foreach (array_slice($functions, 0, 30, true) as $name => $function) {
                $summary .= sprintf("%7.1f %7.1f  %s\n", 100 * $function['self'] / max(1, $samples), 100 * $function['inclusive'] / max(1, $samples), $name);
            }
            return [
                'summary.txt' => $summary,
                'collapsed' => $log->formatCollapsed(),
                'speedscope.json' => json_encode($log->getSpeedscopeData()),
            ];
        };
    } elseif ($profile && $profiler === 'xhprof' && function_exists('xhprof_enable')) {
        xhprof_enable(XHPROF_FLAGS_MEMORY);
        $stop = static function () use ($header): array {
            $data = xhprof_disable();
            // Per function: calls, inclusive and exclusive wall time, memory; the 30 with the most exclusive time
            $functions = [];
            $empty = ['calls' => 0, 'incl' => 0, 'excl' => 0, 'mem' => 0];
            foreach ($data as $key => $metrics) {
                // fib@2 is the second level of recursion of fib: merged with fib, its time is already in the inclusive time of fib
                $pair = explode('==>', $key);
                $child = preg_replace('/@\d+$/', '', $pair[1] ?? $pair[0]);
                $recursion = $child !== ($pair[1] ?? $pair[0]);
                $functions[$child] = $functions[$child] ?? $empty;
                $functions[$child]['calls'] += $metrics['ct'];
                $functions[$child]['excl'] += $metrics['wt'];
                if (!$recursion) {
                    $functions[$child]['incl'] += $metrics['wt'];
                    $functions[$child]['mem'] += $metrics['mu'] ?? 0;
                }
                if (isset($pair[1])) {
                    $parent = preg_replace('/@\d+$/', '', $pair[0]);
                    $functions[$parent] = $functions[$parent] ?? $empty;
                    $functions[$parent]['excl'] -= $metrics['wt'];
                }
            }
            $total = $functions['main()']['incl'] ?? 0;
            uasort($functions, static function (array $a, array $b): int {
                return $b['excl'] <=> $a['excl'];
            });
            $summary = $header($total / 1000, 'XHProf');
            $summary .= sprintf("%8s %10s %10s %10s  %s\n", 'calls', 'incl. ms', 'excl. ms', 'mem. KB', 'function');
            foreach (array_slice($functions, 0, 30, true) as $name => $function) {
                $summary .= sprintf("%8d %10.2f %10.2f %10.0f  %s\n", $function['calls'], $function['incl'] / 1000, $function['excl'] / 1000, $function['mem'] / 1024, $name);
            }
            return ['summary.txt' => $summary, 'xhprof.json' => json_encode($data)];
        };
    }

    if (isset($stop)) {
        $start = microtime(true);
        // Registered from a shutdown function, it runs after the shutdown functions of the application
        register_shutdown_function(static function () use ($stop, $setting, $start): void {
            register_shutdown_function(static function () use ($stop, $setting, $start): void {
                $files = $stop();
                $dir = rtrim($setting('output_dir', '/tmp/php-profiles'), '/');
                if (!is_dir($dir) && !@mkdir($dir, 0777, true) && !is_dir($dir)) {
                    error_log("PHP profiler: cannot create $dir");
                    return;
                }
                // 20261120-143012-4242-GET-checkout or 20261120-143012-4242-cli-console
                if (PHP_SAPI === 'cli') {
                    $what = 'cli-'.basename($_SERVER['argv'][0] ?? 'php', '.php');
                } else {
                    $path = trim((string) parse_url($_SERVER['REQUEST_URI'] ?? '/', PHP_URL_PATH), '/');
                    $what = ($_SERVER['REQUEST_METHOD'] ?? 'GET').'-'.($path === '' ? 'root' : $path);
                }
                $what = substr(trim((string) preg_replace('/[^A-Za-z0-9._-]+/', '-', $what), '-'), 0, 80);
                $base = $dir.'/'.date('Ymd-His', (int) $start).'-'.getmypid().'-'.$what;
                foreach ($files as $extension => $content) {
                    if (@file_put_contents("$base.$extension", $content) === false) {
                        error_log("PHP profiler: cannot write $base.$extension");
                    }
                }
            });
        });
    }

    return $setting('prepend');
})();

// The auto_prepend_file of PHP_INI_AUTO_PREPEND_FILE, run in the global scope like any prepended file
if ($thecodingmachineProfilerPrepend !== '') {
    require $thecodingmachineProfilerPrepend;
}
unset($thecodingmachineProfilerPrepend);
