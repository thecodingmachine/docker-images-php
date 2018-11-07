<?php
/**
 * A very simple script in charge of installing extensions based on environment variables.
 * The script is run "ONBUILD".
 */

require 'utils.php';

echo "*** Installing extensions ***\n";

$extensions = getExtensions();

// Let's check that selected extensions can actually be built.

$invalidExtensions = [];

foreach ($extensions as $extension) {
    if (!is_dir(EXTENSIONS_INSTALL_DIR.$extension)) {
        $invalidExtensions[] = $extension;
    }
}

if ($invalidExtensions) {
    file_put_contents('php://stderr', sprintf("The following extension(s) is not supported: %s\n", implode(', ', $invalidExtensions)));
    file_put_contents('php://stderr', sprintf("Supported extensions: %s\n", implode(', ', getCompilableExtensions())));
    exit(1);
}

if (!$extensions) {
    echo "No extensions installed in ONBUILD hook.\n";
}

foreach ($extensions as $extension) {
    passthru('cd ' .EXTENSIONS_INSTALL_DIR.$extension. ' && ./install.sh');
}
