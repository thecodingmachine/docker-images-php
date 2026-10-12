# PHP configuration (php.ini)

## Base php.ini file

By default, the base `php.ini` file is the [*development* php.ini](https://github.com/php/php-src/blob/PHP-8.4/php.ini-development)
file that comes with PHP. The `TEMPLATE_PHP_INI` variable selects the *production* one instead:

```bash
TEMPLATE_PHP_INI=production
```

## Setting php.ini parameters

The `PHP_INI_<parameter>` environment variables set any `php.ini` parameter:

```yml
services:
  my_app:
    image: thecodingmachine/php:8.4-v5-apache
    environment:
      # memory_limit=1g
      PHP_INI_MEMORY_LIMIT: 1g
      # error_reporting=E_ALL
      PHP_INI_ERROR_REPORTING: E_ALL
```

If the parameter contains a dot (`.`), replace it with a double underscore (`__`):

```bash
# opcache.validate_timestamps=0
PHP_INI_OPCACHE__VALIDATE_TIMESTAMPS=0
# intl.default_locale=fr_FR.UTF-8
PHP_INI_INTL__DEFAULT_LOCALE=fr_FR.UTF-8
```

The parameters are applied to PHP CLI and to the PHP of the *apache* or *fpm* variant.
