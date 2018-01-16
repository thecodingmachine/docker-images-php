# Fat Docker PHP images

This repository contains a set of **fat** PHP images for Docker.

Fat? It means the images come with the most common PHP extensions.
     
 - You can enable or disable the extensions using environment variables.
 - You can also modify the `php.ini` settings using environment variables.
 - 3 variants available: `CLI`, `apache` and `fpm`
 - Images are bundled with cron. Cron jobs can be configured using environment variables
 - Images come with Composer and Prestissimo installed
 - All variants can be installed with or without NodeJS (if you need to build your static assets).

## Apache

### php:7.1-apache

| Name                                      | PHP version                | NodeJS version  |
|-------------------------------------------|----------------------------|-----------------|
| php:7.1-apache       | `7.1` | *N/A*           |
| php:7.1-apache-node6 | `7.1` | `6.x`           |
| php:7.1-apache-node8 | `7.1` | `8.x`           |
| php:7.1-fpm          | `7.1` | *N/A*           |
| php:7.1-fpm-node6    | `7.1` | `6.x`           |
| php:7.1-fpm-node8    | `7.1` | `8.x`           |
| php:7.1-cli          | `7.1` | *N/A*           |
| php:7.1-cli-node6    | `7.1` | `6.x`           |
| php:7.1-cli-node8    | `7.1` | `8.x`           |

## Extensions available

Below is a list of extensions available in this image:

**Enabled by default:** apcu mbstring mysqli opcache pdo pdo_mysql redis zip soap

**Disabled by default:** amqp bcmath bz2 calendar dba enchant exif ftp gd gettext gmp igbinary imap intl ldap mcrypt memcached mongodb pcntl pdo_dblib pdo_pgsql pgsql pspell shmop snmp sockets sysvmsg sysvsem sysvshm tidy wddx weakref(-beta) xdebug xmlrpc xsl yaml

## Enabling/disabling extensions

You can enable/disable extensions using the `ENABLE_[extension_name]_EXTENSION` environment variable.

For instance:

```yml
version: '3'
services:
  my_app:
    image: thecodingmachine/php-apache:7.1-node<no value>
    environment:
      # Enable the PostgreSQL extension
      ENABLE_PGSQL_EXTENSION=1
      # Disable the Mysqli extension (otherwise it is enabled by default)
      ENABLE_MYSQLI_EXTENSION=0
```


## Setting parameters in php.ini

You can override parameters in `php.ini` using the PHP_INI_XXX environment variables:

```yml
version: '3'
services:
  my_app:
    image: thecodingmachine/php-apache:7.1-node<no value>
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

## Debugging

To enable XDebug, you simply have to set the environment variable:

```bash
ENABLE_XDEBUG_EXTENSION=1
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
