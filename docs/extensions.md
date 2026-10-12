# PHP extensions

The images come in 2 *types*:

- the **slim** images contain only the basic extensions: you would typically use them in a `Dockerfile` that compiles
  the extensions your application needs;
- the **fat** images contain the most commonly used extensions, ready to be enabled with environment variables: you
  would typically use them in a local or CI environment.

## Extensions of the slim images

These extensions are enabled by default in the slim images: `calendar` `ctype` `curl` `date` `dom` `exif` `fileinfo`
`filter` `ftp` `gettext` `iconv` `json` `mbstring` `opcache` `openssl` `pcntl` `pcre` `PDO` `Phar` `posix` `readline`
`Reflection` `session` `shmop` `SimpleXML` `sockets` `sodium` `SPL` `sysvmsg` `sysvsem` `sysvshm` `tokenizer` `xml`
`xmlreader` `xmlwriter` `xsl` `zip`

This list can be outdated, you can verify it with: `docker run --rm thecodingmachine/php:8.4-v5-slim-cli php -m`

## Extensions of the fat images

**Enabled by default (in addition to the extensions of the slim images):** `apcu` `hash` `iconv` `igbinary` `mysqli`
`mysqlnd` `pdo_mysql` `redis` `soap` `xsl` `zlib`

**Available (can be enabled with environment variables):** `amqp` `ast` `bcmath` `blackfire` `bz2` `dba` `decimal`
`ds` `enchant` `exif` `excimer` `ffi` `mailparse` `msgpack` `gd` `gettext` `gmp` `gnupg` `grpc` `igbinary` `imagick`
`imap` `inotify` `intl` `ldap` `lz4` `mcrypt` `memcached` `mongodb` `odbc` `opentelemetry` `pcov` `pdo_dblib`
`pdo_odbc` `pdo_pgsql` `pdo_sqlite` `pgsql` `pspell` `rdkafka` `shmop` `snmp` `sockets` `sqlite3` `swoole` `tidy`
`uploadprogress` `uuid` `xdebug` `xmlrpc` `xsl` `yaml` `zstd`

This list can be outdated, you can verify it with: `docker run --rm thecodingmachine/php:8.4-v5-cli php -m`

**Notes:**

- *ev* is not available in PHP 8.1+
- *mcrypt* is deprecated and its usage is discouraged: it is provided for legacy applications only
- *imagick* supports SVG, WMF, DjVu and OpenEXR images in addition to the common formats. If you process untrusted
  images, you can restrict the allowed formats in the ImageMagick policy (`/etc/ImageMagick-6/policy.xml`)
- The extensions required by an enabled extension are enabled with it, even if they are disabled: `igbinary` and
  `msgpack` for *memcached*, `igbinary` for *redis*, `mbstring` for *mailparse*, `curl` and `mysqlnd` for *swoole*,
  `mysqlnd` for *mysqli* and *pdo_mysql*
- To debug or profile your application with *xdebug* or *blackfire*, see [Debugging and profiling](debugging.md)

## Enabling/disabling extensions in the fat images

Use the `PHP_EXTENSION_<extension name>` environment variables:

```yml
services:
  my_app:
    image: thecodingmachine/php:8.4-v5-apache
    environment:
      # Enable the PostgreSQL extension
      PHP_EXTENSION_PGSQL: 1
      # Disable the Mysqli extension (enabled by default)
      PHP_EXTENSION_MYSQLI: 0
```

As an alternative, the `PHP_EXTENSIONS` variable lists the extensions to enable:

```bash
PHP_EXTENSIONS=pgsql gettext imap
```

## Compiling extensions in the slim images

With a slim image, the `PHP_EXTENSIONS` ARG lists the extensions to install during the build:

```Dockerfile
ARG PHP_EXTENSIONS="apcu mysqli pdo_mysql redis soap"
FROM thecodingmachine/php:8.4-v5-slim-apache
# The build automatically downloads and compiles the extensions
# (thanks to an ONBUILD hook in the slim image)
```

Beware:

- The `ARG PHP_EXTENSIONS` instruction must be written before the `FROM`. This is not a typo.
- `ARG PHP_EXTENSIONS=""` is not the same as `ENV PHP_EXTENSIONS=""`.
- `ARG PHP_EXTENSION_<extension name>` (like the environment variables of the fat images) is not supported.
- With a multi-stage build, the `ARG` must be at the very top of the file (before the first `FROM`):

```Dockerfile
# The PHP_EXTENSIONS ARG applies to the slim image
ARG PHP_EXTENSIONS="apcu mysqli pdo_mysql soap"

FROM thecodingmachine/php:8.4-v5-apache-node24 AS builder

COPY --chown=docker:docker sources/web .
RUN composer install &&\
    yarn install &&\
    yarn build

# The slim image builds the extensions listed at the very top of the file
FROM thecodingmachine/php:8.4-v5-slim-apache

ENV APP_ENV=prod \
    APACHE_DOCUMENT_ROOT=public/

COPY --from=builder /var/www/html .
```

In this example, the fat image runs the `yarn build`, and the result is copied in a slim image that does not contain
NodeJS and contains only the required extensions.
