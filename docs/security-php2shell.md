# php2shell: CVE-2026-109618 and CVE-2026-109619

On 2026-10-21, the PHP project disclosed two critical vulnerabilities in the PHP core (CVSS v4 9.2), known as
*php2shell*. They can allow unauthenticated remote code execution on any PHP installation serving web requests
(`mod_php`, PHP-FPM...). Exploits are public: update your images now.

| Images                                          | Status                                                                     |
|-------------------------------------------------|----------------------------------------------------------------------------|
| v5, PHP 8.2 to 8.5                              | **Fixed**: PHP 8.2.35, 8.3.36, 8.4.27 and 8.5.12                           |
| v5, PHP 7.4, 8.0 and 8.1                        | **Fixed**: backport applied, same PHP version (7.4.33, 8.0.30, 8.1.34)     |
| v5, `-node18` and `-node20` (PHP 8.2+) variants | **Vulnerable**: no longer built, [see NodeJS](#nodejs-variants)            |
| v4 (all PHP versions)                           | **Vulnerable**: not rebuilt, [migrate to v5](#v4-images-are-not-fixed)     |

## Maintained versions (PHP 8.2 to 8.5)

The PHP project released fixed versions: 8.2.35, 8.3.36, 8.4.27 and 8.5.12. The images are rebuilt with them, as
for any PHP patch release:

- the `X.Y-v5-*` tags (e.g. `8.4-v5-apache`) contain the fixed version;
- the `X.Y.Z-v5-*` tags of older patch versions (e.g. `8.4.26-v5-apache`) are frozen and **remain vulnerable**: do
  not use them.

## Non-maintained versions (PHP 7.4, 8.0 and 8.1)

These versions are end of life: the PHP project did not release a new version. Its security team published a minimal
backport of the fix in the sources only (the `PHP-7.4-CVE-2026-109618-109619`, `PHP-8.0-CVE-2026-109618-109619` and
`PHP-8.1-CVE-2026-109618-109619` branches of [php-src](https://github.com/php/php-src)). The packages of
[packages.sury.org](https://packages.sury.org/php/), used by the images, include this backport.

The images of these versions are not rebuilt every week: they were rebuilt manually with the fixed packages. As the
backport **does not change the PHP version**, the tags did not change either:

- `7.4-v5-*`, `8.0-v5-*` and `8.1-v5-*` contain the fix;
- `7.4.33-v5-*`, `8.0.30-v5-*` and `8.1.34-v5-*` were overwritten with the fixed images.

`php -v` still prints 7.4.33, 8.0.30 or 8.1.34: it does not tell whether the image is fixed. The backport adds the
`zend_mm_safe_error_ex` function to the PHP engine, which can be searched in the PHP binaries of the image (CLI,
PHP-FPM and `mod_php`):

```bash
$ docker run --rm thecodingmachine/php:8.1-v5-apache bash -c \
    'for BIN in /usr/bin/php${PHP_VERSION} /usr/sbin/php-fpm${PHP_VERSION} /usr/lib/apache2/modules/libphp${PHP_VERSION}.so; do
       [ -e "${BIN}" ] && (grep -q zend_mm_safe_error_ex "${BIN}" && echo "fixed ${BIN}" || echo "VULNERABLE ${BIN}")
     done'
```

Non-maintained versions get this exceptional fix because of the severity of the vulnerability, not other fixes:
[plan your upgrade](../README.md#supported-versions).

## NodeJS variants

Only the NodeJS variants of the [list of images](../README.md#images) are rebuilt:

| PHP versions | Rebuilt NodeJS variants                    | Not rebuilt: **vulnerable** |
|--------------|--------------------------------------------|-----------------------------|
| 8.2 to 8.5   | `-node22`, `-node24`, `-node26`            | `-node18`, `-node20`        |
| 7.4 to 8.1   | `-node20`, `-node22`, `-node24`, `-node26` | `-node18`                   |

The tags of the other NodeJS versions (e.g. `8.3-v5-apache-node20` or `8.1-v5-cli-node18`) were published before
these versions were dropped: they are frozen and contain a vulnerable PHP.

**Use a maintained NodeJS version** (22, 24 or 26, see [Supported versions](../README.md#supported-versions)):
switching to a rebuilt variant (e.g. `8.3-v5-apache-node22` instead of `8.3-v5-apache-node20`) fixes PHP and keeps
NodeJS up to date.

If your project cannot change its NodeJS version yet, build your image from the slim image, which is fixed, and install
the NodeJS version you need with the `NODE_VERSION` ARG (written before the `FROM`, see
[NodeJS](advanced.md#nodejs)):

```Dockerfile
ARG NODE_VERSION=20
ARG PHP_EXTENSIONS="intl pdo_mysql"
FROM thecodingmachine/php:8.3-v5-slim-apache
```

The slim image does not contain the extensions of the fat image: list the ones you need in `PHP_EXTENSIONS` (see
[PHP extensions](extensions.md)). NodeJS 18 and 20 are end of life and no longer get security fixes: this is a
temporary solution, plan the upgrade of NodeJS.

## Updating your images

The images are fixed, not your containers: pull the images and recreate the containers, and rebuild the images built
from ours.

```bash
$ docker compose pull && docker compose up -d
$ docker build --pull -t my-app .
```

In the CI, check that the base image is pulled again (e.g. `docker build --pull`) and not taken from a cache.

The test suite checks that the images are not vulnerable
([`tests-suite/php-security-patches.sh`](../tests-suite/php-security-patches.sh)): an image that fails it is not
published.

## v4 images are not fixed

The v4 images (e.g. `8.1-v4-apache`) are based on Ubuntu 20.04, for which PHP packages are no longer built. They
**are not rebuilt and remain vulnerable**, whatever their PHP version and NodeJS variant.

Migrate to the v5 images: v5 is mostly compatible with v4, the main change being the Ubuntu version (20.04 to 24.04).
See the [migration notes](../MIGRATING.md#migrating-from-v4-to-v5-images).
