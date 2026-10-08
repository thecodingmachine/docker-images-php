# Variants: cli, apache and fpm

| Variant | Default command      | Working directory | Port                                                            |
|---------|----------------------|-------------------|-----------------------------------------------------------------|
| cli     | `php -v`             | `/usr/src/app`    | -                                                               |
| apache  | `apache2-foreground` | `/var/www/html`   | `80` (HTTP)                                                     |
| fpm     | `php-fpm`            | `/var/www/html`   | `9000` (FastCGI, no HTTP), `80` (HTTP) with the built-in Apache |

Mount or copy your application in the working directory.

## cli

The *cli* images expect a command: override the Docker *command*, never the *entrypoint* (it configures PHP, the
user, the cron jobs... see [Processes](processes.md)).

```Dockerfile
FROM thecodingmachine/php:8.4-v5-cli

CMD ["php", "myprogram.php", "some_param"]
```

```yml
services:
  my_app:
    image: thecodingmachine/php:8.4-v5-cli
    command: php myprogram.php some_param
```

## apache

Apache runs PHP with `mod_php`. The sections below also apply to the [built-in Apache of the *fpm* variant](#built-in-apache).

### Document root

`APACHE_DOCUMENT_ROOT` sets the document root (your "public" directory). A relative path is relative to
`/var/www/html`:

```bash
# These 2 variables are identical
APACHE_DOCUMENT_ROOT=public/
APACHE_DOCUMENT_ROOT=/var/www/html/public
```

### Ports

Apache listens on port 80 (and 443 when the `ssl` module is enabled). `APACHE_HTTP_PORT` and `APACHE_HTTPS_PORT`
change these ports, for instance to use unprivileged ports:

```bash
APACHE_HTTP_PORT=8080
APACHE_HTTPS_PORT=8443
```

### Apache modules

Use the `APACHE_EXTENSION_<module name>` environment variables:

```yml
services:
  my_app:
    image: thecodingmachine/php:8.4-v5-apache
    environment:
      APACHE_EXTENSION_DAV: 1
      APACHE_EXTENSION_SSL: 1
```

As an alternative, the `APACHE_EXTENSIONS` variable lists the modules to enable:

```bash
APACHE_EXTENSIONS="dav ssl"
```

**Modules enabled by default:** `access_compat` `alias` `auth_basic` `authn_core` `authn_file` `authz_core`
`authz_host` `authz_user` `autoindex` `deflate` `dir` `env` `expires` `filter` `mime` `mpm_prefork` `negotiation`
`php8.x` (your PHP version) `reqtimeout` `rewrite` `setenvif` `status`

For the built-in Apache of the *fpm* variant, `mpm_event` `proxy` `proxy_fcgi` are enabled instead of `mpm_prefork` and
`php8.x` (`mod_php` is not available).

**Modules available:** `access_compat` `actions` `alias` `allowmethods` `asis` `auth_basic` `auth_digest` `auth_form`
`authn_anon` `authn_core` `authn_dbd` `authn_dbm` `authn_file` `authn_socache` `authnz_fcgi` `authnz_ldap`
`authz_core` `authz_dbd` `authz_dbm` `authz_groupfile` `authz_host` `authz_owner` `authz_user` `autoindex` `brotli`
`buffer` `cache` `cache_disk` `cache_socache` `cern_meta` `cgi` `cgid` `charset_lite` `data` `dav` `dav_fs`
`dav_lock` `dbd` `deflate` `dialup` `dir` `dump_io` `echo` `env` `ext_filter` `expires` `file_cache` `filter`
`headers` `heartbeat` `heartmonitor` `ident` `imagemap` `include` `info` `lbmethod_bybusyness`
`lbmethod_byrequests` `lbmethod_bytraffic` `lbmethod_heartbeat` `ldap` `log_debug` `log_forensic` `lua` `macro` `md`
`mime` `mime_magic` `mpm_event` `mpm_prefork` `mpm_worker` `negotiation` `php8.x` `proxy` `proxy_ajp`
`proxy_balancer` `proxy_connect` `proxy_express` `proxy_fcgi` `proxy_fdpass` `proxy_ftp` `proxy_hcheck` `proxy_html`
`proxy_http` `proxy_scgi` `proxy_uwsgi` `proxy_wstunnel` `ratelimit` `reflector` `remoteip` `reqtimeout` `request`
`rewrite` `sed` `session` `session_cookie` `session_crypto` `session_dbd` `setenvif` `slotmem_plain` `slotmem_shm`
`socache_dbm` `socache_memcache` `socache_redis` `socache_shmcb` `speling` `ssl` `status` `substitute` `suexec`
`unique_id` `userdir` `usertrack` `vhost_alias` `xml2enc`

This list can be outdated, you can verify it with: `docker run --rm thecodingmachine/php:8.4-v5-slim-apache a2enmod`

### Apache user

Apache runs as the `docker` user, which has the rights of the owner of your files (see
[Permissions](advanced.md#permissions)). In production, run it as `www-data` instead:

```Dockerfile
FROM thecodingmachine/php:8.4-v5-apache

ENV APACHE_RUN_USER=www-data \
    APACHE_RUN_GROUP=www-data
```

## fpm

PHP-FPM listens on port 9000 and speaks FastCGI, not HTTP: put a web server (nginx, Caddy, Apache...) in front of it,
in another container, and point it to `fpm-container:9000`.

```bash
$ docker run -p 9000:9000 --rm -v "$PWD":/var/www/html thecodingmachine/php:8.4-v5-fpm
```

A `docker stop` stops PHP-FPM gracefully (`SIGQUIT`), with or without the built-in Apache: the running requests are
completed.

### Built-in Apache

With `PHP_FPM_WEB_SERVER=apache`, the *fpm* variant runs Apache in front of PHP-FPM, in the same container:

```bash
$ docker run -p 80:80 --rm -e PHP_FPM_WEB_SERVER=apache -v "$PWD":/var/www/html thecodingmachine/php:8.4-v5-fpm
```

- Apache uses the threaded `mpm_event` MPM instead of `mpm_prefork` (required by `mod_php`): static files and
  keep-alive connections no longer hold a process embedding PHP, so the memory usage is lower and the container
  handles more concurrent connections (see [the benchmark](../benchmarks/fpm-apache)). HTTP/2 can also be enabled with `APACHE_EXTENSION_HTTP2=1`.
- The Apache features of the *apache* variant are available (`.htaccess`, [document root](#document-root),
  [ports](#ports), [modules](#apache-modules)).
- The number of PHP workers is configured independently (see [PHP-FPM settings](#php-fpm-settings)).
- If Apache or PHP-FPM stops, the other one is stopped too and the container exits (so that your orchestrator can restart it).

It is meant to replace the *apache* variant (`mod_php`). When migrating, be aware that:

- `php_value` and `php_flag` directives are not supported in `.htaccess` files (Apache answers with a 500 error):
  use the `PHP_INI_*` environment variables or a [`.user.ini` file](https://www.php.net/manual/en/configuration.file.per-user.php) instead.
- The `Authorization` header is forwarded to PHP (`CGIPassAuth On`).
- Environment variables are read by PHP-FPM itself: they are no longer exposed through Apache (`PassEnv`).
- The PHP-FPM access log is disabled (Apache already writes one).

### PHP-FPM settings

The PHP-FPM process manager can be configured with environment variables (the defaults are the ones of the Ubuntu
package):

| Environment variable           | `php-fpm.conf` setting  | Default           |
|--------------------------------|-------------------------|-------------------|
| `PHP_FPM_PM`                   | `pm`                    | `dynamic`         |
| `PHP_FPM_PM_MAX_CHILDREN`      | `pm.max_children`       | `5`               |
| `PHP_FPM_PM_START_SERVERS`     | `pm.start_servers`      | `2`               |
| `PHP_FPM_PM_MIN_SPARE_SERVERS` | `pm.min_spare_servers`  | `1`               |
| `PHP_FPM_PM_MAX_SPARE_SERVERS` | `pm.max_spare_servers`  | `3`               |
| `PHP_FPM_PM_MAX_REQUESTS`      | `pm.max_requests`       | `0`               |
| `PHP_FPM_ACCESS_LOG`           | `access.log`            | `/proc/self/fd/2` |

The `php-fpm-healthcheck` command checks that PHP-FPM answers (on its `/ping` endpoint). You can use it as a Docker
healthcheck or as a Kubernetes probe:

```yml
services:
  my_app:
    image: thecodingmachine/php:8.4-v5-fpm
    healthcheck:
      test: ["CMD", "php-fpm-healthcheck"]
```
