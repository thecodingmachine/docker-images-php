# php2shell: CVE-2026-109618 and CVE-2026-109619

Two critical vulnerabilities of PHP (CVSS 9.2), disclosed on 2026-10-21, allow remote code execution without
authentication. Exploits are public: update now.

All the v5 images are fixed, from PHP 7.4 to 8.5, with or without NodeJS (`-node18` to `-node26`).

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
