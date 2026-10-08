# Change Log
## Version 5

### Minor changes

* **2026-10-09**
  * Accept the `http2` and `proxy_http2` Apache modules in `APACHE_EXTENSION_*` (HTTP/2 requires a threaded MPM such as `mpm_event`: it is not served with the `mpm_prefork` MPM required by mod_php)
  * Fix switching the Apache MPM with `APACHE_EXTENSION_*` (modules are now disabled before being enabled, the MPM last)
  * Upgrade Supercronic from 0.1.9 to 0.2.49 (built with an up-to-date Go version)
  * Fix Composer and NodeJS binaries (`vendor/bin`, `node_modules/.bin` and global Composer binaries) not found by `docker exec` / `docker compose exec` when run without their path
  * Fix extensions that could not be loaded without another extension: the required extensions are now enabled with them (`memcached` requires `igbinary` and `msgpack`, `redis` requires `igbinary`, `mailparse` requires `mbstring` and `swoole` requires `curl`)
  * Fix the container start when the mounted directory belongs to an ID used by a system account of the image (e.g. 998 for a `gitlab-runner` user): the commands were run with this account (no home directory, no sudo) instead of the `docker` user
  * Fix `DOCKER_USER` set to an ID used by a system account of the image (`usermod: UID already exists`)
  * Fix `php` run by a user that cannot use sudo (e.g. `sudo -u www-data php ...`): sudo password errors, and failure when a `PHP_*` variable had changed
  * Fix PHP warnings (e.g. an extension that cannot be loaded) breaking the container start: they were written in `generated_conf.ini`, in the crontab and in the startup commands
  * Fix the fpm variant stop: PHP-FPM is now stopped gracefully (`SIGQUIT`: running requests are completed) and port 9000 is exposed
  * Fix stop requests sent while the apache or fpm container is starting: the stop signal (`SIGWINCH` / `SIGQUIT`) was ignored by the entrypoint and the container was killed after the stop timeout
  * Fix Apache modules listed in the documentation but rejected by `APACHE_EXTENSION_*`: `brotli`, `cern_meta`, `imagemap`, `md`, `proxy_hcheck`, `proxy_uwsgi`, `socache_redis`
  * Images built from a slim image are ~105MB lighter: the apt binary caches (`/var/cache/apt/*.bin`) were left by the ONBUILD hook (even without any extension), and the hook no longer runs apt when `PHP_EXTENSIONS` is empty
  * Fat images are ~105MB lighter (same apt binary caches left after installing the extensions)

* **2026-10-06**
  * Fix ev and event extensions on PHP 7.4 (ev pinned to 1.1.5, event dependencies updated for Ubuntu 24.04)

* **2026-10-05**
  * The build now fails when an extension cannot be installed (failures were silently ignored)
  * Fix rdkafka: installed from the stable package (6.0.5) instead of an alpha version, and now available on PHP 8.5
  * Fix Blackfire CLI missing since its versioning switched to calendar versions
  * Fix swoole requiring mysqlnd
  * Document the supported PHP and NodeJS versions
  * Add the `decimal`, `gnupg`, `inotify`, `lz4`, `mcrypt`, `odbc`, `pdo_odbc` and `zstd` extensions on PHP 8.2+
  * Remove the unused `weakref` extension (PHP provides `WeakReference` natively since 7.4)
  * Support for Node v26 (corepack is now installed with npm since NodeJS no longer bundles it from v25)
  * PHP 8.1 and Node v20 (end of life) are no longer built by the main workflow: they are only built by the legacy workflow (Node v20 for PHP 8.1, 8.0 and 7.4)

* **2025-11-26**
  * Support for PHP 8.5

### Initial

**2025-01-27**
  * Upgrade the base version from Ubuntu 20.04 to 24.04
  * Default blackfire version is now the version 2 (v1 is still available with BLACKFIRE_VERSION=1 at buildtime but with securities issues)
  * Removing tags of version php / node who are no more supported 

## Version 4

### Minor changes

* **2024-05-31**
  * Support for Node v22

* **2023-12-13**
  * Support for PHP 8.3
  * Support for Node v20

* **2022-12-18**
  * Support for PHP 8.2

* **2021-09-22** 
  * Preview for PHP 8.1 | PHP 8.1 in release candidate 2 (miss many extensions)
  * Support for Node v16 | Version LTS
  * Support more PHP 8.0 extensions | Added : mongodb, swoole, zip and blackfire.
  * Enhance builder | Use BuildKit, add header to blueprint exported files and start a Makefile for common build usages.

### Initial

#### New features

- Support for PHP 8.0
- Support for Node 14

#### Breaking changes

- Base image is Ubuntu 20.04
- Dropped Node 8 images
- Dropped PHP 7.1

### Version 3

### Initial

#### Important changes

v2 images are based on a Debian Stretch. v3 images are based on Ubuntu 18.04.
Interally, v3 images are built from the Ondrej PPA. This is a radical change from v2 that was built from the official PHP Docker image. As a result, the v3 image do not have PECL installed, nor a build environment. This makes the v3 images ~200MB lighter.

#### Changes in extensions

The following extensions are now enabled by default: calendar exif pcntl shmop sockets sysvmsg sysvsem sysvshm wddx zip
The sqlite3 extension was previously enabled by default, but must now be enabled manually

### Version 2

### Initial

#### New features

- thecodingmachine/php image now has a "slim" variant that does not contain any extension but that can be used
  to [build the extensions very easily](https://github.com/thecodingmachine/docker-images-php/blob/dfdaa984f0fcc3d66a1b9fef5a6643582deb4d0d/README.md#compiling-extensions-in-the-slim-image).

#### Breaking changes

- PHP 7.1 base image is now **Debian Stretch**
- Dropped Node 6 images

#### New extensions

- Imagick

#### Organization

The project layout has been deeply changed. There is now only one branch for all the PHP versions.
Each extension now has its own installation script in the `/extensions/core` directory with symlinks for the 
extensions in the `/extensions/8.3` and `/extensions/8.4` directory based on the targeted PHP version.
