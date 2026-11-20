# Security

## How the security releases of PHP are handled

The images take PHP from [Ondřej Surý's packages](https://packages.sury.org/php/). When a security release of PHP is
announced:

1. An issue is opened on this repository: subscribe to it to be notified, ask your questions there. Its description
   gives the state of each image, checked every 5 minutes, and a comment is posted when it changes, every 30 minutes at
   most.
2. Each PHP version is rebuilt as soon as its fixed packages are published on amd64 **or** arm64, and rebuilt again
   when the other arch follows: sury publishes the arm64 packages later, sometimes a day later.

Outside of the security releases, each PHP version is also rebuilt within a few hours when sury publishes new packages.

The tags of the images:

- `X.Y-v5-*` (e.g. `8.4-v5-apache`) is updated at each build: use it to get the fixes.
- `X.Y.Z-v5-*` (e.g. `8.4.28-v5-apache`) is only published once amd64 and arm64 have the same PHP version, and never
  changes afterwards.
- PHP 7.4, 8.0 and 8.1 are not maintained: they are rebuilt when sury publishes a fix for them, which keeps the PHP
  version number, without new `X.Y.Z` tag.

## Maintainers: following a security release

[`php-watch.yml`](../.github/workflows/php-watch.yml) checks the packages of sury every hour, and launches
`workflow.yml` and `legacy-v5.yml` for each PHP version whose images do not have them. The schedules of GitHub can
start hours late: for a security release, launch it by hand the day before, it checks every 5 minutes from `start_at`:

```bash
$ gh variable set SECURITY_RELEASE --body 1
$ gh workflow run php-watch.yml --ref v5 -f issue=437 -f start_at="2026-12-17 13:45" -f until="2026-12-19 14:00" \
    -f fixed="8.5=8.5.14 8.4=8.4.29 8.3=8.3.38 8.2=8.2.37"
```

- `fixed` gives the fixed versions once they are known (the watch can be launched again with them): the table says
  fixed or vulnerable instead of up to date. Without `fixed`, the watch stops as soon as the images have the packages
  of sury.
- `SECURITY_RELEASE=1` pauses the builds of the pushes, of the pull requests and of the weekly schedule: only the
  rebuilds of the watch publish images. The label `force-ci` runs the CI of a pull request anyway.
- Afterwards: `gh variable set SECURITY_RELEASE --body 0`, then `gh workflow run workflow.yml --ref v5` to publish the
  commits merged meanwhile.

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

- 2026-11-19: [17 vulnerabilities](https://www.php.net/archive/2026.php#2026-11-19-4), 7 of them critical
  (CVE-2026-115560, CVE-2026-126714, CVE-2026-129481, CVE-2026-129496, CVE-2026-129289, CVE-2026-129474,
  CVE-2026-129182), fixed in PHP 8.2.36, 8.3.37, 8.4.28 and 8.5.13. PHP 7.4, 8.0 and 8.1 got the sury backport of the
  12 vulnerabilities fixed in 8.2.36 (`1:7.4.33-36`, `1:8.0.30-30`, `8.1.34-13`). All the v5 images were fixed on amd64
  on 2026-11-19 and on arm64 on 2026-11-20. See [issue #437](https://github.com/thecodingmachine/docker-images-php/issues/437).
- 2026-10-21: [php2shell](https://github.com/thecodingmachine/docker-images-php/blob/94f9647557c4fb8af550ba714c49bbf566a33458/docs/security-php2shell.md)
  (CVE-2026-109618 and CVE-2026-109619), fixed in all the v5 images.
