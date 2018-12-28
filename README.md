[![Build Status](https://travis-ci.org/thecodingmachine/docker-images-php.svg?branch=v2)](https://travis-ci.org/thecodingmachine/docker-images-php)

# General purpose PHP images for Docker

This repository contains a set of developer-friendly, general purpose PHP images for Docker.

 - You can enable or disable the extensions using environment variables.
 - You can also modify the `php.ini` settings using environment variables.
 - 2 types available: `slim` (no extensions preloaded) or `fat` (most common PHP extensions are built-in)
 - 3 variants available: `CLI`, `apache` and `fpm`
 - Fat images are bundled with [Supercronic](https://github.com/aptible/supercronic) which is a Cron compatible task runner. Cron jobs can be configured using environment variables
 - Fat images come with [Composer](https://getcomposer.org/) and [Prestissimo](https://github.com/hirak/prestissimo) installed
 - All variants can be installed with or without NodeJS (if you need to build your static assets).
 - Everything is done to limit file permission issues that often arise when using Docker. The image is actively tested on Linux, Windows and MacOS


## Images



| Name                                                                    | PHP version                  | type |variant | NodeJS version  | Size 
|-------------------------------------------------------------------------|------------------------------|------|--------|-----------------|------
| [thecodingmachine/php:7.3-v2-apache](https://github.com/thecodingmachine/docker-images-php/blob/v2/Dockerfile.7.3.apache)             | `7.3.x` | fat | apache  | *N/A*           | [![](https://images.microbadger.com/badges/image/thecodingmachine/php:7.3-v2-apache.svg)](https://microbadger.com/images/thecodingmachine/php:7.3-v2-apache)
| [thecodingmachine/php:7.3-v2-apache-node8](https://github.com/thecodingmachine/docker-images-php/blob/v2/Dockerfile.7.3.apache.node8) | `7.3.x` | fat | apache  | `8.x`           | [![](https://images.microbadger.com/badges/image/thecodingmachine/php:7.3-v2-apache-node8.svg)](https://microbadger.com/images/thecodingmachine/php:7.3-v2-apache-node8)
| [thecodingmachine/php:7.3-v2-apache-node10](https://github.com/thecodingmachine/docker-images-php/blob/v2/Dockerfile.7.3.apache.node10) | `7.3.x` | fat | apache  | `10.x`           | [![](https://images.microbadger.com/badges/image/thecodingmachine/php:7.3-v2-apache-node10.svg)](https://microbadger.com/images/thecodingmachine/php:7.3-v2-apache-node10)
| [thecodingmachine/php:7.3-v2-fpm](https://github.com/thecodingmachine/docker-images-php/blob/v2/Dockerfile.7.3.fpm)                   | `7.3.x` | fat | fpm     | *N/A*           | [![](https://images.microbadger.com/badges/image/thecodingmachine/php:7.3-v2-fpm.svg)](https://microbadger.com/images/thecodingmachine/php:7.3-v2-fpm)
| [thecodingmachine/php:7.3-v2-fpm-node8](https://github.com/thecodingmachine/docker-images-php/blob/v2/Dockerfile.7.3.fpm.node8)       | `7.3.x` | fat | fpm     | `8.x`           | [![](https://images.microbadger.com/badges/image/thecodingmachine/php:7.3-v2-fpm-node8.svg)](https://microbadger.com/images/thecodingmachine/php:7.3-v2-fpm-node8)
| [thecodingmachine/php:7.3-v2-fpm-node10](https://github.com/thecodingmachine/docker-images-php/blob/v2/Dockerfile.7.3.fpm.node10)       | `7.3.x` | fat | fpm     | `10.x`           | [![](https://images.microbadger.com/badges/image/thecodingmachine/php:7.3-v2-fpm-node10.svg)](https://microbadger.com/images/thecodingmachine/php:7.3-v2-fpm-node10)
| [thecodingmachine/php:7.3-v2-cli](https://github.com/thecodingmachine/docker-images-php/blob/v2/Dockerfile.7.3.cli)                   | `7.3.x` | fat | cli     | *N/A*           | [![](https://images.microbadger.com/badges/image/thecodingmachine/php:7.3-v2-cli.svg)](https://microbadger.com/images/thecodingmachine/php:7.3-v2-cli)
| [thecodingmachine/php:7.3-v2-cli-node8](https://github.com/thecodingmachine/docker-images-php/blob/v2/Dockerfile.7.3.cli.node8)       | `7.3.x` | fat | cli     | `8.x`           | [![](https://images.microbadger.com/badges/image/thecodingmachine/php:7.3-v2-cli-node8.svg)](https://microbadger.com/images/thecodingmachine/php:7.3-v2-cli-node8)
| [thecodingmachine/php:7.3-v2-cli-node10](https://github.com/thecodingmachine/docker-images-php/blob/v2/Dockerfile.7.3.cli.node10)       | `7.3.x` | fat | cli     | `10.x`           | [![](https://images.microbadger.com/badges/image/thecodingmachine/php:7.3-v2-cli-node10.svg)](https://microbadger.com/images/thecodingmachine/php:7.3-v2-cli-node10)
| [thecodingmachine/php:7.3-v2-slim-apache](https://github.com/thecodingmachine/docker-images-php/blob/v2/Dockerfile.7.3.slim.apache)             | `7.3.x` | slim | apache  | *N/A*           | [![](https://images.microbadger.com/badges/image/thecodingmachine/php:7.3-v2-slim-apache.svg)](https://microbadger.com/images/thecodingmachine/php:7.3-v2-slim-apache)
| [thecodingmachine/php:7.3-v2-slim-fpm](https://github.com/thecodingmachine/docker-images-php/blob/v2/Dockerfile.7.3.slim.fpm)                   | `7.3.x` | slim | fpm     | *N/A*           | [![](https://images.microbadger.com/badges/image/thecodingmachine/php:7.3-v2-slim-fpm.svg)](https://microbadger.com/images/thecodingmachine/php:7.3-v2-slim-fpm)
| [thecodingmachine/php:7.3-v2-slim-cli](https://github.com/thecodingmachine/docker-images-php/blob/v2/Dockerfile.7.3.slim.cli)                   | `7.3.x` | slim | cli     | *N/A*           | [![](https://images.microbadger.com/badges/image/thecodingmachine/php:7.3-v2-slim-cli.svg)](https://microbadger.com/images/thecodingmachine/php:7.3-v2-slim-cli)
| [thecodingmachine/php:7.2-v2-apache](https://github.com/thecodingmachine/docker-images-php/blob/v2/Dockerfile.7.2.apache)             | `7.2.x` | fat | apache  | *N/A*           | [![](https://images.microbadger.com/badges/image/thecodingmachine/php:7.2-v2-apache.svg)](https://microbadger.com/images/thecodingmachine/php:7.2-v2-apache)
| [thecodingmachine/php:7.2-v2-apache-node8](https://github.com/thecodingmachine/docker-images-php/blob/v2/Dockerfile.7.2.apache.node8) | `7.2.x` | fat | apache  | `8.x`           | [![](https://images.microbadger.com/badges/image/thecodingmachine/php:7.2-v2-apache-node8.svg)](https://microbadger.com/images/thecodingmachine/php:7.2-v2-apache-node8)
| [thecodingmachine/php:7.2-v2-apache-node10](https://github.com/thecodingmachine/docker-images-php/blob/v2/Dockerfile.7.2.apache.node10) | `7.2.x` | fat | apache  | `10.x`           | [![](https://images.microbadger.com/badges/image/thecodingmachine/php:7.2-v2-apache-node10.svg)](https://microbadger.com/images/thecodingmachine/php:7.2-v2-apache-node10)
| [thecodingmachine/php:7.2-v2-fpm](https://github.com/thecodingmachine/docker-images-php/blob/v2/Dockerfile.7.2.fpm)                   | `7.2.x` | fat | fpm     | *N/A*           | [![](https://images.microbadger.com/badges/image/thecodingmachine/php:7.2-v2-fpm.svg)](https://microbadger.com/images/thecodingmachine/php:7.2-v2-fpm)
| [thecodingmachine/php:7.2-v2-fpm-node8](https://github.com/thecodingmachine/docker-images-php/blob/v2/Dockerfile.7.2.fpm.node8)       | `7.2.x` | fat | fpm     | `8.x`           | [![](https://images.microbadger.com/badges/image/thecodingmachine/php:7.2-v2-fpm-node8.svg)](https://microbadger.com/images/thecodingmachine/php:7.2-v2-fpm-node8)
| [thecodingmachine/php:7.2-v2-fpm-node10](https://github.com/thecodingmachine/docker-images-php/blob/v2/Dockerfile.7.2.fpm.node10)       | `7.2.x` | fat | fpm     | `10.x`           | [![](https://images.microbadger.com/badges/image/thecodingmachine/php:7.2-v2-fpm-node10.svg)](https://microbadger.com/images/thecodingmachine/php:7.2-v2-fpm-node10)
| [thecodingmachine/php:7.2-v2-cli](https://github.com/thecodingmachine/docker-images-php/blob/v2/Dockerfile.7.2.cli)                   | `7.2.x` | fat | cli     | *N/A*           | [![](https://images.microbadger.com/badges/image/thecodingmachine/php:7.2-v2-cli.svg)](https://microbadger.com/images/thecodingmachine/php:7.2-v2-cli)
| [thecodingmachine/php:7.2-v2-cli-node8](https://github.com/thecodingmachine/docker-images-php/blob/v2/Dockerfile.7.2.cli.node8)       | `7.2.x` | fat | cli     | `8.x`           | [![](https://images.microbadger.com/badges/image/thecodingmachine/php:7.2-v2-cli-node8.svg)](https://microbadger.com/images/thecodingmachine/php:7.2-v2-cli-node8)
| [thecodingmachine/php:7.2-v2-cli-node10](https://github.com/thecodingmachine/docker-images-php/blob/v2/Dockerfile.7.2.cli.node10)       | `7.2.x` | fat | cli     | `10.x`           | [![](https://images.microbadger.com/badges/image/thecodingmachine/php:7.2-v2-cli-node10.svg)](https://microbadger.com/images/thecodingmachine/php:7.2-v2-cli-node10)
| [thecodingmachine/php:7.2-v2-slim-apache](https://github.com/thecodingmachine/docker-images-php/blob/v2/Dockerfile.7.2.slim.apache)             | `7.2.x` | slim | apache  | *N/A*           | [![](https://images.microbadger.com/badges/image/thecodingmachine/php:7.2-v2-slim-apache.svg)](https://microbadger.com/images/thecodingmachine/php:7.2-v2-slim-apache)
| [thecodingmachine/php:7.2-v2-slim-fpm](https://github.com/thecodingmachine/docker-images-php/blob/v2/Dockerfile.7.2.slim.fpm)                   | `7.2.x` | slim | fpm     | *N/A*           | [![](https://images.microbadger.com/badges/image/thecodingmachine/php:7.2-v2-slim-fpm.svg)](https://microbadger.com/images/thecodingmachine/php:7.2-v2-slim-fpm)
| [thecodingmachine/php:7.2-v2-slim-cli](https://github.com/thecodingmachine/docker-images-php/blob/v2/Dockerfile.7.2.slim.cli)                   | `7.2.x` | slim | cli     | *N/A*           | [![](https://images.microbadger.com/badges/image/thecodingmachine/php:7.2-v2-slim-cli.svg)](https://microbadger.com/images/thecodingmachine/php:7.2-v2-slim-cli)
| [thecodingmachine/php:7.1-v2-apache](https://github.com/thecodingmachine/docker-images-php/blob/v2/Dockerfile.7.1.apache)             | `7.1.x` | fat | apache  | *N/A*           | [![](https://images.microbadger.com/badges/image/thecodingmachine/php:7.1-v2-apache.svg)](https://microbadger.com/images/thecodingmachine/php:7.1-v2-apache)
| [thecodingmachine/php:7.1-v2-apache-node8](https://github.com/thecodingmachine/docker-images-php/blob/v2/Dockerfile.7.1.apache.node8) | `7.1.x` | fat | apache  | `8.x`           | [![](https://images.microbadger.com/badges/image/thecodingmachine/php:7.1-v2-apache-node8.svg)](https://microbadger.com/images/thecodingmachine/php:7.1-v2-apache-node8)
| [thecodingmachine/php:7.1-v2-apache-node10](https://github.com/thecodingmachine/docker-images-php/blob/v2/Dockerfile.7.1.apache.node10) | `7.1.x` | fat | apache  | `10.x`           | [![](https://images.microbadger.com/badges/image/thecodingmachine/php:7.1-v2-apache-node10.svg)](https://microbadger.com/images/thecodingmachine/php:7.1-v2-apache-node10)
| [thecodingmachine/php:7.1-v2-fpm](https://github.com/thecodingmachine/docker-images-php/blob/v2/Dockerfile.7.1.fpm)                   | `7.1.x` | fat | fpm     | *N/A*           | [![](https://images.microbadger.com/badges/image/thecodingmachine/php:7.1-v2-fpm.svg)](https://microbadger.com/images/thecodingmachine/php:7.1-v2-fpm)
| [thecodingmachine/php:7.1-v2-fpm-node8](https://github.com/thecodingmachine/docker-images-php/blob/v2/Dockerfile.7.1.fpm.node8)       | `7.1.x` | fat | fpm     | `8.x`           | [![](https://images.microbadger.com/badges/image/thecodingmachine/php:7.1-v2-fpm-node8.svg)](https://microbadger.com/images/thecodingmachine/php:7.1-v2-fpm-node8)
| [thecodingmachine/php:7.1-v2-fpm-node10](https://github.com/thecodingmachine/docker-images-php/blob/v2/Dockerfile.7.1.fpm.node10)       | `7.1.x` | fat | fpm     | `10.x`           | [![](https://images.microbadger.com/badges/image/thecodingmachine/php:7.1-v2-fpm-node10.svg)](https://microbadger.com/images/thecodingmachine/php:7.1-v2-fpm-node10)
| [thecodingmachine/php:7.1-v2-cli](https://github.com/thecodingmachine/docker-images-php/blob/v2/Dockerfile.7.1.cli)                   | `7.1.x` | fat | cli     | *N/A*           | [![](https://images.microbadger.com/badges/image/thecodingmachine/php:7.1-v2-cli.svg)](https://microbadger.com/images/thecodingmachine/php:7.1-v2-cli)
| [thecodingmachine/php:7.1-v2-cli-node8](https://github.com/thecodingmachine/docker-images-php/blob/v2/Dockerfile.7.1.cli.node8)       | `7.1.x` | fat | cli     | `8.x`           | [![](https://images.microbadger.com/badges/image/thecodingmachine/php:7.1-v2-cli-node8.svg)](https://microbadger.com/images/thecodingmachine/php:7.1-v2-cli-node8)
| [thecodingmachine/php:7.1-v2-cli-node10](https://github.com/thecodingmachine/docker-images-php/blob/v2/Dockerfile.7.1.cli.node10)       | `7.1.x` | fat | cli     | `10.x`           | [![](https://images.microbadger.com/badges/image/thecodingmachine/php:7.1-v2-cli-node10.svg)](https://microbadger.com/images/thecodingmachine/php:7.1-v2-cli-node10)
| [thecodingmachine/php:7.1-v2-slim-apache](https://github.com/thecodingmachine/docker-images-php/blob/v2/Dockerfile.7.1.slim.apache)             | `7.1.x` | slim | apache  | *N/A*           | [![](https://images.microbadger.com/badges/image/thecodingmachine/php:7.1-v2-slim-apache.svg)](https://microbadger.com/images/thecodingmachine/php:7.1-v2-slim-apache)
| [thecodingmachine/php:7.1-v2-slim-fpm](https://github.com/thecodingmachine/docker-images-php/blob/v2/Dockerfile.7.1.slim.fpm)                   | `7.1.x` | slim | fpm     | *N/A*           | [![](https://images.microbadger.com/badges/image/thecodingmachine/php:7.1-v2-slim-fpm.svg)](https://microbadger.com/images/thecodingmachine/php:7.1-v2-slim-fpm)
| [thecodingmachine/php:7.1-v2-slim-cli](https://github.com/thecodingmachine/docker-images-php/blob/v2/Dockerfile.7.1.slim.cli)                   | `7.1.x` | slim | cli     | *N/A*           | [![](https://images.microbadger.com/badges/image/thecodingmachine/php:7.1-v2-slim-cli.svg)](https://microbadger.com/images/thecodingmachine/php:7.1-v2-slim-cli)


Note: we do not tag patch releases of PHP, only minor versions. You will find one image for PHP 7.1, one for PHP 7.2, 
but no tagged image for PHP 7.1.12. This is because we believe you have no valid reason to ask explicitly for 7.1.12.
When 7.1.13 is out, you certainly want to upgrade automatically to this patch release since patch releases contain only bugfixes.

Images are automatically updated when a new patch version of PHP is released, so the PHP 7.1 image will always contain 
the most up-to-date version of the PHP 7.1.x branch. If you want to automatically update your images on your production
environment, you can use tools like [watchtower](https://github.com/v2tec/watchtower) that will monitor new versions of
the images and update your environment on the fly.

## Usage

These images are based on the [official PHP image](https://hub.docker.com/_/php/).

Example with CLI:

```bash
$ docker run -it --rm --name my-running-script -v "$PWD":/usr/src/app thecodingmachine/php:7.2-v2-cli php your-script.php
```

Example with Apache:

```bash
$ docker run -p 80:80 --rm --name my-apache-php-app -v "$PWD":/var/www/html thecodingmachine/php:7.2-v2-apache
```

Example with PHP-FPM:

```bash
$ docker run -p 9000:9000 --rm --name my-php-fpm -v "$PWD":/var/www/html thecodingmachine/php:7.2-v2-fpm
```

Example with Apache + Node 8.x in a Dockerfile:

**Dockerfile**
```Dockerfile
FROM thecodingmachine/php:7.2-v2-apache-node8

COPY src/ /var/www/html/
RUN composer install
RUN npm install
RUN npm run build
```

## Extensions available

This image comes with 2 "types": the *slim* and the **fat** image.

The slim image contains no extensions. But it provides a simple way to install them. You would typically use the "slim"
image in a `Dockerfile` when building your own custom image.

The fat image contains the most commonly used extensions. You would typically use it in a local or CI environment.

### Compiled extensions

For both types, these extensions are **compiled in PHP** (cannot be disabled): mbstring ftp mysqlnd

### Fat image

Below is a list of extensions available in this image:

**Enabled by default:** apcu mysqli opcache pdo pdo_mysql redis zip soap

**Available (can be enabled using environment variables):** amqp ast bcmath blackfire bz2 calendar dba ds enchant ev event exif mailparse gd gettext gmp gnupg igbinary imagick imap intl ldap mcrypt memcached mongodb pcntl pdo_dblib pdo_pgsql pgsql pspell shmop snmp sockets swoole sysvmsg sysvsem sysvshm tidy wddx weakref(-beta) xdebug xmlrpc xsl yaml

**Note**: as of 2018-12-13, PHP 7.3 has just been released and some extensions are not yet ready:

- *amqp* extension is not compatible with PHP 7.3 yet
- *mcrypt* is not available anymore in PHP 7.3
- *weakref* is not compatible with PHP 7.3 ([there might not be a version for PHP 7.3](https://wiki.php.net/rfc/weakrefs))
- *xdebug* is provided in version 2.7.0beta1

### Enabling/disabling extensions in the fat image

You can enable/disable extensions using the `PHP_EXTENSION_[extension_name]` environment variable.

For instance:

```yml
version: '3'
services:
  my_app:
    image: thecodingmachine/php:7.2-v2-apache-node8
    environment:
      # Enable the PostgreSQL extension
      PHP_EXTENSION_PGSQL: 1
      # Disable the Mysqli extension (otherwise it is enabled by default)
      PHP_EXTENSION_MYSQLI: 0
```

As an alternative, you can use the `PHP_EXTENSIONS` global variable:

```
PHP_EXTENSIONS=pgsql gettext imap sockets
```

### Compiling extensions in the slim image

If you are using the slim image, you can automatically compile the extensions using the `PHP_EXTENSIONS` ARG in your Dockerfile.

```Dockerfile
ARG PHP_EXTENSIONS="apcu mysqli opcache pdo pdo_mysql redis zip soap"
FROM thecodingmachine/php:7.2-v2-slim-apache
# The build will automatically trigger the download and compilation
# of the extensions (thanks to a ONBUILD hook in the slim image)
```

Beware! The `ARG PHP_EXTENSIONS` command must be written before the `FROM`. This is not a typo.

Note: the slim image comes with literally no extensions. Not even "opcache" which is definitely useful performance-wise.
We highly recommend to install at least the "opcache" extension.

**Heads up**: if you are using multistage builds, the "ARG" variable must be put at the very top of the file (before the 
first FROM):

```Dockerfile
# The PHP_EXTENSIONS ARG will apply to the "slim" image
ARG PHP_EXTENSIONS="apcu mysqli opcache pdo pdo_mysql zip soap"

FROM thecodingmachine/php:7.2-v2-apache-node10 AS builder

COPY --chown=docker:docker sources/web .
RUN composer install &&\
    yarn install &&\
    yarn build

# The slim image will automatically build the extensions from the list provided at the very top of the file.
FROM thecodingmachine/php:7.2-v2-slim-apache

ENV APP_ENV=prod \
    APACHE_DOCUMENT_ROOT=/public

COPY --from=builder /var/www/html .
```

In the sample above, we use the fat image to perform a "yarn build", but copy the result in a slim image that does
not contain Node, and contains only required extensions.

## Setting parameters in php.ini

By default, the base `php.ini` file used is the [*development* php.ini](https://github.com/php/php-src/blob/PHP-7.2/php.ini-development) file that comes with PHP. 

You can use the production `php.ini` file using the `TEMPLATE_PHP_INI` environment variable:

```
# Use the production php.ini file as a base
TEMPLATE_PHP_INI=production
```

You can override parameters in `php.ini` using the PHP_INI_XXX environment variables:

```yml
version: '3'
services:
  my_app:
    image: thecodingmachine/php:7.2-v2-apache-node8
    environment:
      # set the parameter memory_limit=1g
      PHP_INI_MEMORY_LIMIT: 1g
      # set the parameter error_reporting=EALL
      PHP_INI_ERROR_REPORTING: E_ALL
```

Absolutely all `php.ini` parameters can be set.

Internally, the image will map all environment variables starting with `PHP_INI_`.

If your `php.ini` parameter contains a dot ("."), you can replace it with a double underscore ("__").

For instance:

```
# Will set the parameter xdebug.remote_autostart=1
PHP_INI_XDEBUG__REMOTE_AUTOSTART=1
```

## Default working directory

The working directory (the directory in which you should mount/copy your application) depends on the image variant
you are using:

| Variant | Working directory |
|---------|-------------------|
| cli     | `/usr/src/app`    |
| apache  | `/var/www/html`   |
| fpm     | `/var/www/html`   |


## Changing Apache document root

For the *apache* variant, you can change the document root of Apache (i.e. your "public" directory) by using the 
`APACHE_DOCUMENT_ROOT` variable:

```
# The root of your website is in the "public" directory:
APACHE_DOCUMENT_ROOT=public/
```

## Enabling/disabling Apache extensions

You can enable/disable Apache extensions using the `APACHE_EXTENSION_[extension_name]` environment variable.

For instance:

```yml
version: '3'
services:
  my_app:
    image: thecodingmachine/php:7.2-v2-apache-node8
    environment:
      # Enable the DAV extension for Apache
      APACHE_EXTENSION_DAV: 1
      # Enable the SSL extension for Apache
      APACHE_EXTENSION_SSL: 1
```

As an alternative, you can use the `APACHE_EXTENSIONS` global variable:

```
PHP_EXTENSIONS="dav ssl"
```

**Apache modules enabled by default:** access_compat, alias, auth_basic, authn_core, authn_file, authz_core, authz_host, authz_user, autoindex, deflate, dir, env, expires, filter, mime, mpm_prefork, negotiation, php7, reqtimeout, rewrite, setenvif, status

**Apache modules available:** access_compat, actions, alias, allowmethods, asis, auth_basic, auth_digest, auth_form, authn_anon, authn_core, authn_dbd, authn_dbm, authn_file, authn_socache, authnz_fcgi, authnz_ldap, authz_core, authz_dbd, authz_dbm, authz_groupfile, authz_host, authz_owner, authz_user, autoindex, buffer, cache, cache_disk, cache_socache, cgi, cgid, charset_lite, data, dav, dav_fs, dav_lock, dbd, deflate, dialup, dir, dump_io, echo, env, ext_filter, file_cache, filter, headers, heartbeat, heartmonitor, ident, include, info, lbmethod_bybusyness, lbmethod_byrequests, lbmethod_bytraffic, lbmethod_heartbeat, ldap, log_debug, log_forensic, lua, macro, mime, mime_magic, mpm_event, mpm_prefork, mpm_worker, negotiation, php7, proxy, proxy_ajp, proxy_balancer, proxy_connect, proxy_express, proxy_fcgi, proxy_fdpass, proxy_ftp, proxy_html, proxy_http, proxy_scgi, proxy_wstunnel, ratelimit, reflector, remoteip, reqtimeout, request, rewrite, sed, session, session_cookie, session_crypto, session_dbd, setenvif, slotmem_plain, slotmem_shm, socache_dbm, socache_memcache, socache_shmcb, speling, ssl, status, substitute, suexec, unique_id, userdir, usertrack, vhost_alias, xml2enc

 
## Debugging

To enable XDebug, you simply have to set the environment variable:

```bash
PHP_EXTENSION_XDEBUG=1
```
 
If you enable XDebug, the image will do its best to configure the `xdebug.remote_host` to point back to your Docker host.

Behind the scenes, the image will:

- set the parameter `xdebug.remote_enable=1`
- if you are using a Linux or Windows machine, the `xdebug.remote_host` IP will point to your Docker gateway
- if you are using a MaxOS machine, the `xdebug.remote_host` IP will point to [`docker.for.mac.localhost`](https://docs.docker.com/docker-for-mac/networking/#use-cases-and-workarounds)

## NodeJS

The *fat* images come with a Node variant. You can use Node 8 or Node 10. If you need a Node 6 variant, [use thecodingmachine/php v1 images](https://github.com/thecodingmachine/docker-images-php/tree/7.2-v1).

If you use the *slim* images, you can install a NodeJS version with a simple ARG during the build:

```Dockerfile
ARG NODE_VERSION=10
FROM thecodingmachine/php:7.2-v2-slim-apache
# The build will automatically trigger the download of Node 10
# (thanks to a ONBUILD hook in the slim image)
```

Beware! The `ARG NODE_VERSION` command must be written before the `FROM`. This is not a typo.

`NODE_VERSION` can take any valid node versions (from 6 to 11 at the time of writing this README)

## Permissions

Ever faced file permission issues with Docker? Good news, this is a thing of the past!

If you are used to running Docker containers with the base PHP image, you probably noticed that when running commands
(like `composer install`) within the container, files are associated to the `root` user. This is because the base user
of the image is "root".

When you mount your project directory into `/var/www/html`, it would be great if the default user used by Docker could
be your current host user.

The problem with Docker is that the container and the host do not share the same list of users. For instance, you might
be logged in on your host computer as `superdev` (ID: 1000), and the container has no user whose ID is 1000.

The *thecodingmachine/php* images solve this issue with a bit of black magic:

The image contains a user named `docker`. On container startup, the startup script will look at the owner of the 
working directory (`/var/www/html` for Apache/PHP-FPM, or `/usr/src/app` for CLI). The script will then assume that
you want to run commands as this user. So it will **dynamically change the ID of the docker user** to match the ID of
the current working directory user.

Furthermore, the image is changing the Apache default user/group to be `docker/docker` (instead if `www-data/www-data`).
So Apache will run with the same rights as the user on your host.

The direct result is that, in development:

 - Your PHP application can edit any file
 - Your container can edit any file
 - You can still edit any file created by Apache or by the container in CLI

### Using this image in production

By changing the Apache user to be `docker:docker`, we are lowering the security.
This is OK for a development environment, but this should be avoided in production.
Indeed, in production, Apache should not be allowed to edit PHP files of your application. If for some reason, an 
attacker manages to change PHP files using a security hole, he could then run any PHP script by editing the PHP files
of your application.

In production, you want to change back the Apache user to www-data.

This can be done easily:

**Dockerfile**
```
FROM thecodingmachine/php:7.2-v2-apache

# ...

# Change back Apache user and group to www-data
ENV APACHE_RUN_USER=www-data \
    APACHE_RUN_GROUP=www-data
```


## Setting up CRON jobs

You can set up CRON jobs using environment variables too.

To do this, you need to configure 3 variables:

```bash
# configure the user that will run cron (defaults to root)
CRON_USER=root
# configure the schedule for the cron job (here: run every minute)
CRON_SCHEDULE=* * * * *
# last but not least, configure the command
CRON_COMMAND=vendor/bin/console do:stuff
```

By default, CRON output will be redirected to Docker output.

If you have more than one job to run, you can suffix your environment variable with the same string. For instance:

```bash
CRON_USER_1=root
CRON_SCHEDULE_1=* * * * *
CRON_COMMAND_1=vendor/bin/console do:stuff

CRON_USER_2=www-data
CRON_SCHEDULE_2=0 3 * * *
CRON_COMMAND_2=vendor/bin/console other:stuff
```

Cron is **installed by default in the fat images**. If you are using the "*slim*" images, you need to install it by passing
a single argument before the "FROM" clause in your Dockerfile:

```Dockerfile
ARG INSTALL_CRON=1
FROM thecodingmachine/php:7.2-v2-slim-apache
# The build triggers automatically the installation of Cron
```

**Important**: The cron runner we use is "Supercronic" and not the orginial "cron" that has a number of issues
with containers. Even with Supercronic, the architecture of cron was never designed with Docker in mind 
(Cron is way older than Docker). It will run correctly on your container. If at some point you want to scale and add 
more containers, it will run on all your containers. At that point, if you only want to run a Cron task once for your 
application (and not once per container), you might want to have a look at alternative solutions like 
[Tasker](https://github.com/opsxcq/tasker) or use the native features of your orchestrator (if you use Kubernetes,
you have a native task runner available), or one of the many other alternatives.

## Launching commands on container startup

You can launch commands on container startup using the `STARTUP_COMMAND_XXX` environment variables.
This can be very helpful to install dependencies or apply database patches for instance:

```bash
STARTUP_COMMAND_1=composer install
STARTUP_COMMAND_2=vendor/bin/doctrine orm:schema-tool:update 
```

As an alternative, the images will look into the container for an executable file named `/etc/container/startup.sh`.

If such a file is mounted in the image, it will be executed on container startup.

```bash
docker run -it --rm --name my-running-script -v "$PWD":/usr/src/myapp -w /usr/src/myapp \ 
       -v $PWD/my-startup-script.sh:/etc/container/startup.sh thecodingmachine/php:7.2-v2-cli php your-script.php 
```

## Registering SSH private keys

If your PHP project as a dependency on [a package stored in a private GIT repository](https://getcomposer.org/doc/05-repositories.md#using-private-repositories), 
your `composer install` commands will not work unless you register your private key in the container.

You have several options to do this.

### Option 1: mount your keys in the container directly

This option is the easiest way to go if you are using the image on a development environment.

**docker-compose.yml**
```yml
version: '3'
services:
  my_app:
    image: thecodingmachine/php:7.2-v2-apache-node8
    volumes:
      - ~/.ssh:/home/docker/.ssh
```

### Option 2: store the keys from environment variables or build arguments

Look at this option if you are building a Dockerfile from this image.

The first thing to do is to get the signature of the server you want to connect to.

``` bash
$ ssh-keyscan myserver.com
```

Copy the output and put it in an environment variable. We assume the content is stored in `$SSH_KNOWN_HOSTS`.

Now, let's write a Dockerfile.

**Dockerfile**
```yml
FROM thecodingmachine/php:7.2-v2-apache

ARG SSH_PRIVATE_KEY
ARG SSH_KNOWN_HOSTS

# Let's register the private key
RUN ssh-add <(echo "$SSH_PRIVATE_KEY")
# Let's add the server to the list of known hosts.
RUN echo "$SSH_KNOWN_HOSTS" >> ~/.ssh/known_hosts
```

Finally, when triggering the build, you must pass the 2 variables as [build arguments](https://docs.docker.com/engine/reference/commandline/build/#set-build-time-variables-build-arg):

```bash
$ docker build -t my_image --build-arg SSH_PRIVATE_KEY="$SSH_PRIVATE_KEY" --build-arg SSH_KNOWN_HOSTS="$SSH_KNOWN_HOSTS" .
```

## Usage in Kubernetes

If you plan to use this image in Kubernetes, please be aware that the image internally uses `sudo`. This is because the
default user (`docker`) needs to be able to edit php config files as `root`.

Kubernetes has a security setting (`allowPrivilegeEscalation`) that can disallow the use of `sudo`. The use of this flag
breaks the image and in the logs, you will find the message:

```
sudo: effective uid is not 0, is /usr/bin/sudo on a file system with the 'nosuid' option set or an NFS file system without root privileges?
```

Please be sure that this option is never set to false:

```yml
apiVersion: v1
kind: Pod
# ...
spec:
  containers:
  - name: foobar
    image: thecodingmachine/php:7.2-v2-apache
    securityContext:
      allowPrivilegeEscalation: true # never use "false" here.
```

## Profiling with Blackfire

This image comes with the [Blackfire]() PHP probe. You can install it using:

```bash
PHP_EXTENSION_BLACKFIRE=1
```

By default, the image expects that the blackfire agent is started in another container.

Your `docker-compose.yml` file will typically look like this:

**docker-compose.yml**
```yml
version: '3.3'
services:
  php:
    image: thecodingmachine/php:7.2-v2-apache
    ports:
      - "80:80"
    environment:
      PHP_EXTENSION_BLACKFIRE: 1
  blackfire:
    image: blackfire/blackfire
    environment:
        # Exposes the host BLACKFIRE_SERVER_ID and TOKEN environment variables.
        - BLACKFIRE_SERVER_ID
        - BLACKFIRE_SERVER_TOKEN
        # You can also use global environment credentials :
        # BLACKFIRE_SERVER_ID: SERVER-ID
        # BLACKFIRE_SERVER_TOKEN: SERVER-TOKEN
```

See [Blackfire Docker documentation](https://blackfire.io/docs/integrations/docker#running-the-agent) for more information.

The image assumes that the Blackfire agent is accessible via the `blackfire` URL (like in the exemple above).
If for some reason, the container name is not "blackfire", you can customize the agent URL with the `BLACKFIRE_AGENT` environment variable:

**docker-compose.yml**
```yml
version: '3.3'
services:
  php:
    image: thecodingmachine/php:7.2-v2-apache
    environment:
      PHP_EXTENSION_BLACKFIRE: 1
      BLACKFIRE_AGENT: myblackfire
    # ...
  myblackfire:
    image: blackfire/blackfire
    environment:
        # ...
```

## Contributing

There is one branch per minor PHP version and version of the image.

Please submit your pull requests to the lowest branch where is applies.

The Dockerfiles and the README are generated from a template using [Orbit](https://github.com/gulien/orbit).

If you want to modify a Dockerfile or the README, you should instead edit the `utils/Dockerfile.blueprint`
or `utils/README.blueprint.md` and then run the command:

```bash
$ orbit run generate
```

This command will generate all the files from the "blueprint" templates.

You can then test your changes using the `build-and-test.sh` command:

```bash
PHP_VERSION=7.2 BRANCH=v2 VARIANT=apache ./build-and-test.sh
```

## Special thanks

These images have been strongly inspired by [tetraweb/php](https://hub.docker.com/r/tetraweb/php/).
