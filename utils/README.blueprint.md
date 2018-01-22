# Fat Docker PHP images

This repository contains a set of **fat** general purpose PHP images for Docker.

Fat? It means the images come with the most common PHP extensions.
     
 - You can enable or disable the extensions using environment variables.
 - You can also modify the `php.ini` settings using environment variables.
 - 3 variants available: `CLI`, `apache` and `fpm`
 - Images are bundled with cron. Cron jobs can be configured using environment variables
 - Images come with [Composer](https://getcomposer.org/) and [Prestissimo](https://github.com/hirak/prestissimo) installed
 - All variants can be installed with or without NodeJS (if you need to build your static assets).

{{ $image := .Values.Images }}
## Images

| Name                                                                    | PHP version                  | variant | NodeJS version  |
|-------------------------------------------------------------------------|------------------------------|---------|-----------------|
| [php:{{ $image.php_version }}-v1-apache](Dockerfile.apache)             | `{{ $image.php_version }}`.x | apache  | *N/A*           |
| [php:{{ $image.php_version }}-v1-apache-node6](Dockerfile.apache.node6) | `{{ $image.php_version }}`.x | apache  | `6.x`           |
| [php:{{ $image.php_version }}-v1-apache-node8](Dockerfile.apache.node8) | `{{ $image.php_version }}`.x | apache  | `8.x`           |
| [php:{{ $image.php_version }}-v1-fpm](Dockerfile.fpm)                   | `{{ $image.php_version }}`.x | fpm     | *N/A*           |
| [php:{{ $image.php_version }}-v1-fpm-node6](Dockerfile.fpm.node6)       | `{{ $image.php_version }}`.x | fpm     | `6.x`           |
| [php:{{ $image.php_version }}-v1-fpm-node8](Dockerfile.fpm.node8)       | `{{ $image.php_version }}`.x | fpm     | `8.x`           |
| [php:{{ $image.php_version }}-v1-cli](Dockerfile.cli)                   | `{{ $image.php_version }}`.x | cli     | *N/A*           |
| [php:{{ $image.php_version }}-v1-cli-node6](Dockerfile.cli.node6)       | `{{ $image.php_version }}`.x | cli     | `6.x`           |
| [php:{{ $image.php_version }}-v1-cli-node8](Dockerfile.cli.node8)       | `{{ $image.php_version }}`.x | cli     | `8.x`           |

## Usage

These images are based on the [official PHP image](https://hub.docker.com/_/php/).

Example with CLI:

```bash
$ docker run -it --rm --name my-running-script -v "$PWD":/usr/src/myapp -w /usr/src/myapp thecodingmachine/php:7.1-v1-cli php your-script.php
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

**Enabled by default:** {{ $image.enabled_php_extensions }}

**Available (can be enabled using environment variables):** {{ $image.disabled_php_extensions }}

## Enabling/disabling extensions

You can enable/disable extensions using the `PHP_EXTENSION_[extension_name]` environment variable.

For instance:

```yml
version: '3'
services:
  my_app:
    image: thecodingmachine/php:{{ $image.php_version }}-v1-apache-node8
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

You can override parameters in `php.ini` using the PHP_INI_XXX environment variables:

```yml
version: '3'
services:
  my_app:
    image: thecodingmachine/php:{{ $image.php_version }}-v1-apache-node8
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
    image: thecodingmachine/php:{{ $image.php_version }}-v1-apache-node8
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

## Setting up CRON jobs

You can set up CRON jobs using environment variables too.

To do this, you need to configure 3 variables:

```bash
# configure the user that will run cron (defaults to root)
CRON_USER=root
# configure the schedule for the cron job (here: run every minute)
CRON_SCHEDULE=* * * * *
# last but not least, configure the command
CRON_COMMAND=vendir/bin/console do:stuff
```

By default, CRON output will be redirected to Docker output.

If you have more than one job to run, you can suffix your environment variable with the same string. For instance:

```bash
CRON_USER_1=root
CRON_SCHEDULE_1=* * * * *
CRON_COMMAND_1=vendir/bin/console do:stuff

CRON_USER_2=www-data
CRON_SCHEDULE_2=0 3 * * *
CRON_COMMAND_2=vendir/bin/console other:stuff
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
