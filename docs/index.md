# thecodingmachine/php documentation

General purpose PHP images for Docker: *cli*, *apache* and *fpm* variants, slim and fat images, configured with
environment variables. The list of images and the quick start are in the
[README](https://github.com/thecodingmachine/docker-images-php#readme).

## Choose and size

- [Tuning: Apache, mod_php or PHP-FPM](tuning/): describe your traffic, your application and your container, get the
  settings and the variant to use.
- [Variants](variants.md): *cli*, *apache* (document root, ports, modules, connections) and *fpm*.
- [Serving with the fpm variant](fpm.md): built-in Apache or your own web server, constraints of PHP-FPM, migration from
  the *apache* variant.

## Configure

- [PHP extensions](extensions.md)
- [PHP configuration (php.ini)](php-configuration.md)
- [Processes: startup commands, cron jobs and daemons](processes.md)
- [Debugging and profiling](debugging.md)
- [Advanced features](advanced.md)

## Project

- [Security: php2shell](security-php2shell.md)
- [Contributing](contributing.md)

Coming with v6: a [FrankenPHP](https://frankenphp.dev/) variant, previewed in the [tuning page](tuning/).
