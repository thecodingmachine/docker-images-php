<?php
if (!isset($_SERVER['MYVAR'])) {
    echo "No variable set";
} else {
    echo $_SERVER['MYVAR'];
}
echo getenv('MYVAR');