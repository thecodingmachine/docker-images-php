# Security

## Ongoing: PHP security release of 2026-11-19

The PHP security team [announced](https://www.php.net/index.php#2026-11-18-1) critical security releases for
2026-11-19, 14:00-14:30 UTC. The images are rebuilt automatically as soon as the fixed packages are published:
follow [issue #437](https://github.com/thecodingmachine/docker-images-php/issues/437).

## How the security releases of PHP are handled

The images take PHP from [Ondřej Surý's packages](https://packages.sury.org/php/). When a security release of PHP is
announced:

1. An issue is opened on this repository: subscribe to it to be notified, ask your questions there.
2. The CI checks the sury packages every few minutes, then every hour, during the 48 hours after the release.
3. Each PHP version is rebuilt as soon as its fixed packages are published on amd64 **or** arm64, and rebuilt again
   when the other arch follows: sury publishes the arm64 packages later, sometimes a day later.
4. The CI comments the issue at each step: build started, images published, build failed.

The tags of the images:

- `X.Y-v5-*` (e.g. `8.4-v5-apache`) is updated at each build: use it to get the fixes.
- `X.Y.Z-v5-*` (e.g. `8.4.28-v5-apache`) is only published once amd64 and arm64 have the same PHP version, and never
  changes afterwards.
- PHP 7.4, 8.0 and 8.1 are not maintained: they are rebuilt when sury publishes a fix for them, which keeps the PHP
  version number, without new `X.Y.Z` tag.

## What to do once your version is fixed

1. Pull the images again and recreate your containers:

   ```bash
   $ docker compose pull && docker compose up -d
   ```

2. Rebuild the images built from ours, without the cache of the base image:

   ```bash
   $ docker build --pull -t my-app .
   ```

   In your CI, check that the base image is pulled again and not taken from a cache.

3. Check the PHP version of your containers (`php -v`) against the fixed versions given in the issue.

[Watchtower](https://github.com/nicholas-fedor/watchtower) pulls the new versions of the images and recreates the
containers, so that the next security fixes are applied without waiting for you:

```bash
$ docker run -d --name watchtower -v /var/run/docker.sock:/var/run/docker.sock \
    ghcr.io/nicholas-fedor/watchtower
```

The v4 images get no security fix: migrate to v5, see the
[migration notes](../MIGRATING.md#migrating-from-v4-to-v5-images).

## Past advisories

- 2026-10-21: [php2shell](https://github.com/thecodingmachine/docker-images-php/blob/94f9647557c4fb8af550ba714c49bbf566a33458/docs/security-php2shell.md)
  (CVE-2026-109618 and CVE-2026-109619), fixed in all the v5 images.
