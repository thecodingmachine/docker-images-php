# General purpose PHP images for Docker

This repository contains a set of **fat**, developer-friendly, general purpose PHP images for Docker.

Fat? It means the images come with the most common PHP extensions.
     
 - You can enable or disable the extensions using environment variables.
 - You can also modify the `php.ini` settings using environment variables.
 - 3 variants available: `CLI`, `apache` and `fpm`
 - Images are bundled with cron. Cron jobs can be configured using environment variables
 - Images come with [Composer](https://getcomposer.org/) and [Prestissimo](https://github.com/hirak/prestissimo) installed
 - All variants can be installed with or without NodeJS (if you need to build your static assets).
 - Everything is done to limit file permission issues that often arise when using Docker


## Images

| Name                                                                    | PHP version                  | variant | NodeJS version  | Size 
|-------------------------------------------------------------------------|------------------------------|---------|-----------------|------
| [php:7.1-v1-apache](Dockerfile.apache)             | `7.1.x` | apache  | *N/A*           | [![](https://images.microbadger.com/badges/image/thecodingmachine/php:7.1-v1-apache.svg)](https://microbadger.com/images/thecodingmachine/php:7.1-v1-apache)
| [php:7.1-v1-apache-node6](Dockerfile.apache.node6) | `7.1.x` | apache  | `6.x`           | [![](https://images.microbadger.com/badges/image/thecodingmachine/php:7.1-v1-apache-node6.svg)](https://microbadger.com/images/thecodingmachine/php:7.1-v1-apache-node6)
| [php:7.1-v1-apache-node8](Dockerfile.apache.node8) | `7.1.x` | apache  | `8.x`           | [![](https://images.microbadger.com/badges/image/thecodingmachine/php:7.1-v1-apache-node8.svg)](https://microbadger.com/images/thecodingmachine/php:7.1-v1-apache-node8)
| [php:7.1-v1-fpm](Dockerfile.fpm)                   | `7.1.x` | fpm     | *N/A*           | [![](https://images.microbadger.com/badges/image/thecodingmachine/php:7.1-v1-fpm.svg)](https://microbadger.com/images/thecodingmachine/php:7.1-v1-fpm)
| [php:7.1-v1-fpm-node6](Dockerfile.fpm.node6)       | `7.1.x` | fpm     | `6.x`           | [![](https://images.microbadger.com/badges/image/thecodingmachine/php:7.1-v1-fpm-node6.svg)](https://microbadger.com/images/thecodingmachine/php:7.1-v1-fpm-node6)
| [php:7.1-v1-fpm-node8](Dockerfile.fpm.node8)       | `7.1.x` | fpm     | `8.x`           | [![](https://images.microbadger.com/badges/image/thecodingmachine/php:7.1-v1-fpm-node8.svg)](https://microbadger.com/images/thecodingmachine/php:7.1-v1-fpm-node8)
| [php:7.1-v1-cli](Dockerfile.cli)                   | `7.1.x` | cli     | *N/A*           | [![](https://images.microbadger.com/badges/image/thecodingmachine/php:7.1-v1-cli.svg)](https://microbadger.com/images/thecodingmachine/php:7.1-v1-cli)
| [php:7.1-v1-cli-node6](Dockerfile.cli.node6)       | `7.1.x` | cli     | `6.x`           | [![](https://images.microbadger.com/badges/image/thecodingmachine/php:7.1-v1-cli-node6.svg)](https://microbadger.com/images/thecodingmachine/php:7.1-v1-cli-node6)
| [php:7.1-v1-cli-node8](Dockerfile.cli.node8)       | `7.1.x` | cli     | `8.x`           | [![](https://images.microbadger.com/badges/image/thecodingmachine/php:7.1-v1-cli-node8.svg)](https://microbadger.com/images/thecodingmachine/php:7.1-v1-cli-node8)

## Usage

These images are based on the [official PHP image](https://hub.docker.com/_/php/).

Example with CLI:

```bash
$ docker run -it --rm --name my-running-script -v "$PWD":/usr/src/app thecodingmachine/php:7.1-v1-cli php your-script.php
```

Example with Apache:

```bash
$ docker run -p 80:80 --name my-apache-php-app -v "$PWD":/var/www/html thecodingmachine/php:7.1-v1-apache
```

Example with Apache + Node 8.x in a Dockerfile:

**Dockerfile**
```Dockerfile
FROM thecodingmachine/php:7.1-v1-apache-node8

COPY src/ /var/www/html/
RUN composer install
RUN npm install
RUN npm run build
```

## Extensions available

Below is a list of extensions available in this image:

**Enabled by default:** apcu mbstring mysqli opcache pdo pdo_mysql redis zip soap

**Available (can be enabled using environment variables):** amqp ast bcmath bz2 calendar dba enchant ev event exif ftp gd gettext gmp igbinary imap intl ldap mcrypt memcached mongodb pcntl pdo_dblib pdo_pgsql pgsql pspell shmop snmp sockets sysvmsg sysvsem sysvshm tidy wddx weakref(-beta) xdebug xmlrpc xsl yaml

## Enabling/disabling extensions

You can enable/disable extensions using the `PHP_EXTENSION_[extension_name]` environment variable.

For instance:

```yml
version: '3'
services:
  my_app:
    image: thecodingmachine/php:7.1-v1-apache-node8
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


## Setting parameters in php.ini

By default, the base `php.ini` file used is the [*development* php.ini](https://github.com/php/php-src/blob/PHP-7.1/php.ini-development) file that comes with PHP. 

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
    image: thecodingmachine/php:7.1-v1-apache-node8
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
    image: thecodingmachine/php:7.1-v1-apache-node8
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
FROM thecodingmachine/php:7.1-v1-apache

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

**Important**: Cron was never designed with Docker in mind (it is way older than Docker). It will run correctly on
your container. If at some point you want to scale and add more containers, it will run on all your containers.
At that point, if you only want to run a Cron task once for your application (and not once per container), you might
want to have a look at alternative solutions like [Tasker](https://github.com/opsxcq/tasker) or one of the many
other alternatives.

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
       -v $PWD/my-startup-script.sh:/etc/container/startup.sh thecodingmachine/php:7.1-v1-cli php your-script.php 
```

## Special thanks

These images have been strongly inspired by [tetraweb/php](https://hub.docker.com/r/tetraweb/php/).
