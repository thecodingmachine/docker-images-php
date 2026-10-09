<?php
// Simulates a typical page: some CPU work (templating, routing...) and I/O waits (database, cache, API...)
$start = microtime(true);
$data = [];
for ($i = 0; $i < 20000; $i++) {
    $data[] = md5((string) $i);
}
usleep(20000);
$html = '<html><head>';
for ($i = 1; $i <= 10; $i++) {
    $html .= '<link rel="stylesheet" href="/assets/asset' . $i . '.css">';
}
$html .= '</head><body>' . str_repeat('<p>' . $data[array_rand($data)] . '</p>', 200) . '</body></html>';
echo $html;
