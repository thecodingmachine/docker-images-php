# Fat Docker PHP images

This repository contains a set of **fat** PHP images for Docker.

Fat? It means the images come with the most common PHP extensions. You can enable or disable the extensions using 
environment variables. You can also modify the `php.ini` settings using environment variables.

Finally, the images come with NodeJS installed (if you need to build your static assets).




## Apache
{{ $image := .Values.Images.apache }}
### php:{{ $image.php_version }}-apache

| Name                       | Version                                         |
|----------------------------|-------------------------------------------------|
| Xdebug                     | `{{ $image.xdebug_version }}`             |
| NodeJS                     | `{{ $image.node_version }}`               |

## Extensions available

Below is a list of extensions available in this image:

**Enabled by default:**

**Disabled by default:**

## Enabling/disabling extensions

You can enable/disable extensions using the `ENABLE_[extension_name]_EXTENSION` environment variable.

For instance:

```yml
version: '3'
services:
  my_app:
    image: thecodingmachine/php-apache:{{ $image.php_version }}-node{{ $image.node_version }}
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
    image: thecodingmachine/php-apache:{{ $image.php_version }}-node{{ $image.node_version }}
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

