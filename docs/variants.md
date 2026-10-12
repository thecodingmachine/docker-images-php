# Variants: cli, apache and fpm

| Variant | Default command      | Working directory | Port                      |
|---------|----------------------|-------------------|---------------------------|
| cli     | `php -v`             | `/usr/src/app`    | -                         |
| apache  | `apache2-foreground` | `/var/www/html`   | `80` (HTTP)               |
| fpm     | `php-fpm`            | `/var/www/html`   | `9000` (FastCGI, no HTTP) |

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

Apache runs PHP with `mod_php`.

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

A `docker stop` stops PHP-FPM gracefully: the running requests are completed.
