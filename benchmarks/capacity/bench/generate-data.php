<?php
// Catalog of 1000 products (~470 KB of JSON) and 10 static files of 40 KB, always the same
mt_srand(42);
$words = explode(' ', 'lorem ipsum dolor sit amet consectetur adipiscing elit sed do eiusmod tempor incididunt ut labore et dolore magna aliqua ut enim minim veniam quis nostrud');
$categories = ['beauty', 'books', 'garden', 'kitchen', 'music', 'sports', 'tools', 'toys'];
$pick = fn (int $n) => implode(' ', array_map(fn () => $words[mt_rand(0, count($words) - 1)], range(1, $n)));
$products = [];
for ($id = 1; $id <= 1000; $id++) {
    $products[] = [
        'id' => $id,
        'name' => ucwords($pick(3)),
        'category' => $categories[mt_rand(0, count($categories) - 1)],
        'price' => mt_rand(100, 20000) / 100,
        'stock' => mt_rand(0, 200),
        'rating' => mt_rand(10, 50) / 10,
        'description' => $pick(40),
        'tags' => array_values(array_unique(explode(' ', $pick(4)))),
        'created_at' => date(DATE_ATOM, 1767225600 + mt_rand(0, 300) * 86400),
    ];
}
$app = $argv[1];
@mkdir("$app/data");
@mkdir("$app/public/assets");
file_put_contents("$app/data/catalog.json", json_encode($products));
for ($i = 1; $i <= 10; $i++) {
    $bytes = '';
    for ($j = 0; $j < 30000; $j++) {
        $bytes .= chr(mt_rand(0, 255));
    }
    file_put_contents("$app/public/assets/asset$i.css", chunk_split(base64_encode($bytes), 76, "\n"));
}
