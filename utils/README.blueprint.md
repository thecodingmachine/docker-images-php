![Docker PHP Images GitHub workflow](https://github.com/thecodingmachine/docker-images-php/workflows/Docker%20PHP%20Images%20GitHub%20workflow/badge.svg)

# General purpose PHP images for Docker

> **New: built-in Apache in the fpm variant (`PHP_FPM_WEB_SERVER=apache`)**
>
> The *fpm* variant can now run Apache in front of PHP-FPM, in the same container. It is a drop-in alternative to the
> *apache* variant: same Apache features (`.htaccess`, `APACHE_DOCUMENT_ROOT`, `APACHE_EXTENSION_*`), but PHP runs in
> PHP-FPM instead of `mod_php`.
>
> **Why?** `mod_php` forces Apache to dedicate a whole process (embedding PHP) to each connection, including idle
> keep-alive connections and static files. With PHP-FPM, Apache uses its threaded MPM (`mpm_event`) and only PHP
> requests reach the PHP workers. Under the same load ([benchmark](https://github.com/thecodingmachine/docker-images-php/tree/v5/benchmarks/fpm-apache)),
> PHP is not faster, but the container handles **3x more pages per second** with a p95 under 100 ms and a p99 under 1 s
> (30 vs 10 pages/s on 2 CPUs) and uses **4x less memory** (~90 vs ~380 MiB).
>
> ```bash
> $ docker run -p 80:80 -e PHP_FPM_WEB_SERVER=apache -v "$PWD":/var/www/html thecodingmachine/php:{{ .Orbit.Images.php_version }}-v5-fpm
> ```
>
> Migrating from the *apache* variant: see [Built-in Apache of the fpm variant](docs/variants.md#built-in-apache)
> (for instance, `php_value` directives are not supported in `.htaccess` files). The *apache* variant is still available.

This repository contains a set of developer-friendly, general purpose PHP images for Docker.

 - You can enable or disable the extensions using environment variables.
 - You can also modify the `php.ini` settings using environment variables.
 - 2 types available: `slim` (no extensions preloaded) or `fat` (most common PHP extensions are built-in)
 - 3 variants available: `CLI`, `apache` and `fpm` (with an optional built-in Apache)
 - Fat images are bundled with [Supercronic](https://github.com/aptible/supercronic) which is a Cron compatible task runner. Cron jobs can be configured using environment variables
 - All images come with [Composer](https://getcomposer.org/) installed
 - All variants can be installed with or without NodeJS (if you need to build your static assets).
 - Composer binaries (`vendor/bin` and global binaries) and NodeJS binaries (`node_modules/.bin`) can be run without their path, including with `docker exec` / `docker compose exec` (e.g. `docker compose exec app phpstan`)
 - Everything is done to limit file permission issues that often arise when using Docker. The image is actively tested on Linux, Windows and MacOS

See the [documentation](#documentation) for all the features.

{{ $image := .Orbit.Images }}
## Images

{{ $versions := list "8.5" "8.4" "8.3" "8.2" "8.1" }}
{{ $nodeVersions := list "22" "24" "26" }}{{ $legacyVersions := list "8.1" }}{{ $legacyNodeVersions := list "20" "22" "24" "26" }}

| Name                                                                    | PHP version                                                                                                                                        | type                                       |variant | NodeJS version  | Size 
|-------------------------------------------------------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------|--------------------------------------------|--------|-----------------|------
{{range $phpV := $versions}}{{ $nodes := $nodeVersions }}{{ if has $phpV $legacyVersions }}{{ $nodes = $legacyNodeVersions }}{{ end }}| [thecodingmachine/php:{{ $phpV }}-v5-apache](https://github.com/thecodingmachine/docker-images-php/blob/v5/Dockerfile.apache)                      | `{{ $phpV }}.x` | fat  | apache   | *N/A*                                                | [![](https://images.microbadger.com/badges/image/thecodingmachine/php:{{ $phpV }}-v5-apache.svg)](https://microbadger.com/images/thecodingmachine/php:{{ $phpV }}-v5-apache)
{{range $nodeV := $nodes}}| [thecodingmachine/php:{{ $phpV }}-v5-apache-node{{ $nodeV }}](https://github.com/thecodingmachine/docker-images-php/blob/v5/Dockerfile.apache.node) | `{{ $phpV }}.x` | fat  | apache   | `{{ $nodeV }}.x`  | [![](https://images.microbadger.com/badges/image/thecodingmachine/php:{{ $phpV }}-v5-apache-node{{ $nodeV }}.svg)](https://microbadger.com/images/thecodingmachine/php:{{ $phpV }}-v5-apache-node{{ $nodeV }})
{{ end }}| [thecodingmachine/php:{{ $phpV }}-v5-fpm](https://github.com/thecodingmachine/docker-images-php/blob/v5/Dockerfile.fpm)                            | `{{ $phpV }}.x` | fat  | fpm      | *N/A*                                                | [![](https://images.microbadger.com/badges/image/thecodingmachine/php:{{ $phpV }}-v5-fpm.svg)](https://microbadger.com/images/thecodingmachine/php:{{ $phpV }}-v5-fpm)
{{range $nodeV := $nodes}}| [thecodingmachine/php:{{ $phpV }}-v5-fpm-node{{ $nodeV }}](https://github.com/thecodingmachine/docker-images-php/blob/v5/Dockerfile.fpm.node)      | `{{ $phpV }}.x` | fat  | fpm      | `{{ $nodeV }}.x`  | [![](https://images.microbadger.com/badges/image/thecodingmachine/php:{{ $phpV }}-v5-fpm-node{{ $nodeV }}.svg)](https://microbadger.com/images/thecodingmachine/php:{{ $phpV }}-v5-fpm-node{{ $nodeV }})
{{ end }}| [thecodingmachine/php:{{ $phpV }}-v5-cli](https://github.com/thecodingmachine/docker-images-php/blob/v5/Dockerfile.cli)                            | `{{ $phpV }}.x` | fat  | cli      | *N/A*                                                | [![](https://images.microbadger.com/badges/image/thecodingmachine/php:{{ $phpV }}-v5-cli.svg)](https://microbadger.com/images/thecodingmachine/php:{{ $phpV }}-v5-cli)
{{range $nodeV := $nodes}}| [thecodingmachine/php:{{ $phpV }}-v5-cli-node{{ $nodeV }}](https://github.com/thecodingmachine/docker-images-php/blob/v5/Dockerfile.cli.node)      | `{{ $phpV }}.x` | fat  | cli      | `{{ $nodeV }}.x`  | [![](https://images.microbadger.com/badges/image/thecodingmachine/php:{{ $phpV }}-v5-cli-node{{ $nodeV }}.svg)](https://microbadger.com/images/thecodingmachine/php:{{ $phpV }}-v5-cli-node{{ $nodeV }})
{{ end }}| [thecodingmachine/php:{{ $phpV }}-v5-slim-apache](https://github.com/thecodingmachine/docker-images-php/blob/v5/Dockerfile.slim.apache)            | `{{ $phpV }}.x` | slim | apache   | *N/A*                                                | [![](https://images.microbadger.com/badges/image/thecodingmachine/php:{{ $phpV }}-v5-slim-apache.svg)](https://microbadger.com/images/thecodingmachine/php:{{ $phpV }}-v5-slim-apache)
| [thecodingmachine/php:{{ $phpV }}-v5-slim-fpm](https://github.com/thecodingmachine/docker-images-php/blob/v5/Dockerfile.slim.fpm)                                                                | `{{ $phpV }}.x`                                                                                                    | slim                                       | fpm      | *N/A*                                                | [![](https://images.microbadger.com/badges/image/thecodingmachine/php:{{ $phpV }}-v5-slim-fpm.svg)](https://microbadger.com/images/thecodingmachine/php:{{ $phpV }}-v5-slim-fpm)
| [thecodingmachine/php:{{ $phpV }}-v5-slim-cli](https://github.com/thecodingmachine/docker-images-php/blob/v5/Dockerfile.slim.cli)                                                                | `{{ $phpV }}.x`                                                                                                    | slim                                       | cli      | *N/A*                                                | [![](https://images.microbadger.com/badges/image/thecodingmachine/php:{{ $phpV }}-v5-slim-cli.svg)](https://microbadger.com/images/thecodingmachine/php:{{ $phpV }}-v5-slim-cli)
{{end}}
 

Note: we also tag patch releases of PHP versions. So you can specify a specific patch release using thecodingmachine/php:**{{ $image.php_version }}.1**-v5-cli for instance.
However, unless you have a **very specific need** (for instance if the latest patch release of PHP introduced regressions), believe you have no valid reason to ask explicitly for {{ $image.php_version }}.1 for instance.
When {{ $image.php_version }}.2 is out, you certainly want to upgrade automatically to this patch release since patch releases contain only bugfixes.
Also, we automatically rebuild X.Y images every week, but only the latest X.Y.Z patch release gets a rebuild. The other patch releases are frozen in time and will contain bugs and security issues. So use those with great care.

[Major].[minor] images are automatically updated when a new patch version of PHP is released, so the PHP {{ $image.php_version }} image will always contain the most up-to-date version of the PHP {{ $image.php_version }}.x branch.

## Supported versions

We only maintain the PHP and NodeJS versions that are still supported by their respective communities
(see [PHP supported versions](https://www.php.net/supported-versions.php) and [NodeJS releases](https://nodejs.org/en/about/previous-releases)).
Bugs are fixed on maintained versions only.

| PHP version | Status                                        |
|-------------|-----------------------------------------------|
| 8.5         | Maintained (until 2029-12-31)                 |
| 8.4         | Maintained (until 2028-12-31)                 |
| 8.3         | Maintained (until 2027-12-31)                 |
| 8.2         | Maintained (until 2026-12-31)                 |
| 8.1         | **Not maintained** (end of life: 2025-12-31)  |
| 8.0         | **Not maintained** (end of life: 2023-11-26)  |
| 7.4         | **Not maintained** (end of life: 2022-11-28)  |

| NodeJS version | Status                                        |
|----------------|-----------------------------------------------|
| 26             | Maintained (until 2029-04-30)                 |
| 24             | Maintained (until 2028-04-30)                 |
| 22             | Maintained (until 2027-04-30)                 |
| 20             | **Not maintained** (end of life: 2026-04-30)  |

Images of non-maintained versions are still available but no longer receive fixes: use them at your own risk and plan your upgrade.

## Usage

The images are based on Ubuntu 24.04, with PHP from the [ondrej/php](https://launchpad.net/~ondrej/+archive/ubuntu/php) repository.

Example with CLI:

```bash
$ docker run -it --rm --name my-running-script -v "$PWD":/usr/src/app thecodingmachine/php:{{ $image.php_version }}-v5-cli php your-script.php
```

Example with Apache:

```bash
$ docker run -p 80:80 --rm --name my-apache-php-app -v "$PWD":/var/www/html thecodingmachine/php:{{ $image.php_version }}-v5-apache
```

Example with PHP-FPM:

```bash
$ docker run -p 9000:9000 --rm --name my-php-fpm -v "$PWD":/var/www/html thecodingmachine/php:{{ $image.php_version }}-v5-fpm
```

Example with PHP-FPM and its built-in Apache (in the same container):

```bash
$ docker run -p 80:80 --rm --name my-apache-fpm-app -e PHP_FPM_WEB_SERVER=apache -v "$PWD":/var/www/html thecodingmachine/php:{{ $image.php_version }}-v5-fpm
```

Example with Apache + Node {{ $image.node_version }}.x in a Dockerfile:

**Dockerfile**
```Dockerfile
FROM thecodingmachine/php:{{ $image.php_version }}-v5-apache-node{{ $image.node_version }}

COPY src/ /var/www/html/
RUN composer install
RUN npm install
RUN npm run build
```

## Documentation

Most features are configured with environment variables:

| Topic                                              | Content                                                                                        | Main variables                                                     |
|----------------------------------------------------|------------------------------------------------------------------------------------------------|--------------------------------------------------------------------|
| [PHP extensions](docs/extensions.md)               | Extensions of the slim and fat images, enabling them, compiling them in a slim image           | `PHP_EXTENSION_*`, `PHP_EXTENSIONS`                                |
| [PHP configuration](docs/php-configuration.md)     | Base `php.ini` file and `php.ini` parameters                                                   | `TEMPLATE_PHP_INI`, `PHP_INI_*`                                    |
| [Variants](docs/variants.md)                       | *cli*, *apache* (document root, ports, modules, user) and *fpm* (built-in Apache, PHP-FPM)     | `APACHE_DOCUMENT_ROOT`, `APACHE_EXTENSION_*`, `PHP_FPM_WEB_SERVER` |
| [Processes](docs/processes.md)                     | Startup commands, cron jobs and daemons run along with the main command                        | `STARTUP_COMMAND_*`, `CRON_*`, `DAEMON_*`                          |
| [Debugging and profiling](docs/debugging.md)       | Xdebug and Blackfire                                                                           | `PHP_EXTENSION_XDEBUG`, `XDEBUG_CLIENT_HOST`, `BLACKFIRE_AGENT`    |
| [Advanced features](docs/advanced.md)              | Permissions, NodeJS, Composer version, locales, SSH keys, Kubernetes                           | `DOCKER_USER`, `COMPOSER_VERSION`, `LOCALES`                       |

The slim images install some tools during the build of your image with an ARG before the `FROM`: `PHP_EXTENSIONS`,
`INSTALL_CRON`, `INSTALL_LOCALES`, `NODE_VERSION` and `COMPOSER_VERSION`.

## Migrating from older image versions

Check the [migration notes](MIGRATING.md).

## Contributing

The Dockerfiles and this README are generated from the templates of the `utils` directory: see the
[contributing guide](docs/contributing.md) to edit, build and test the images.

## Special thanks

These images have been strongly inspired by [tetraweb/php](https://hub.docker.com/r/tetraweb/php/).
