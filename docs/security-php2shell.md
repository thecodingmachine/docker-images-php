# php2shell: CVE-2026-109618 and CVE-2026-109619

Two critical vulnerabilities of PHP (CVSS 9.2), disclosed on 2026-10-21, allow remote code execution without
authentication. Exploits are public: update now.

All the v5 images are fixed on amd64, from PHP 7.4 to 8.5, with or without NodeJS (`-node18` to `-node26`). The
arm64 images are not fixed yet: see [arm64 images](#arm64-images).

## What to do

1. Pull the images again and recreate your containers:

   ```bash
   $ docker compose pull && docker compose up -d
   ```

2. Rebuild the images built from ours, without the cache of the base image:

   ```bash
   $ docker build --pull -t my-app .
   ```

   In your CI, check that the base image is pulled again and not taken from a cache.

3. Use the `X.Y-v5-*` tags (e.g. `8.4-v5-apache`). The tags of older PHP patch versions (e.g. `8.4.26-v5-apache`) are
   not fixed.

PHP 7.4, 8.0 and 8.1 images still show 7.4.33, 8.0.30 and 8.1.34 in `php -v`: the fix does not change the version.

## arm64 images

The images install PHP from the packages of [packages.sury.org](https://packages.sury.org/php/), which publishes the
fixed packages for amd64 first: the arm64 packages are still being built. Until they are published, all the arm64
images stay vulnerable, including those of the tags of the fixed PHP patch versions (on arm64, `8.4.27-v5-apache`
still contains PHP 8.4.26). The arm64 images will be rebuilt as soon as the packages are available.

Check the PHP version of your image: 8.2.35, 8.3.36, 8.4.27, 8.5.12 or newer are fixed. PHP 7.4, 8.0 and 8.1 keep
their version number, and are fixed when the PHP binary contains the fix:

```bash
$ docker run --rm thecodingmachine/php:8.1-v5-cli bash -c 'grep -c zend_mm_safe_error_ex /usr/bin/php${PHP_VERSION}'
```

`0` means that the image is vulnerable.

In the meantime, an arm64 host can run the amd64 image through emulation (`--platform linux/amd64`, or
`platform: linux/amd64` in a Compose file), which is much slower.

## NodeJS 16 and older

The v5 images are not built with NodeJS 16 and older. Use a maintained NodeJS version (22, 24 or 26) when possible.

If your project still needs an older NodeJS version, start from the slim image and install NodeJS with the
`NODE_VERSION` ARG, written before the `FROM` (see [NodeJS](advanced.md#nodejs)), and the extensions you need with
`PHP_EXTENSIONS` (see [PHP extensions](extensions.md)):

```Dockerfile
ARG NODE_VERSION=16
ARG PHP_EXTENSIONS="intl pdo_mysql"
FROM thecodingmachine/php:8.1-v5-slim-apache
```

These NodeJS versions no longer get security fixes: plan their upgrade.

## v4 images

The v4 images are **not fixed** and will not be. Migrate to v5: see the
[migration notes](../MIGRATING.md#migrating-from-v4-to-v5-images).

## Bonus: update your containers automatically

[Watchtower](https://github.com/nicholas-fedor/watchtower) pulls the new versions of the images and recreates the
containers, so that the next security fixes are applied without waiting for you:

```bash
$ docker run -d --name watchtower -v /var/run/docker.sock:/var/run/docker.sock \
    ghcr.io/nicholas-fedor/watchtower
```

The original `containrrr/watchtower` project is no longer maintained: use this fork.
