# Serving a PHP application with the fpm variant

The *fpm* variant runs [PHP-FPM](https://www.php.net/manual/en/install.fpm.php), which speaks FastCGI (port `9000`),
not HTTP. To serve your application over HTTP, you need a web server in front of it:

- the **built-in Apache** of the image (`PHP_FPM_WEB_SERVER=apache`): one container, no web server configuration;
- or **your own web server** (nginx, Caddy, Traefik...) in another container.

## Built-in Apache

```bash
$ docker run -p 80:80 -e PHP_FPM_WEB_SERVER=apache -v "$PWD":/var/www/html thecodingmachine/php:8.4-v5-fpm
```

```yml
services:
  app:
    image: thecodingmachine/php:8.4-v5-fpm
    ports:
      - "80:80"
    environment:
      PHP_FPM_WEB_SERVER: apache
      APACHE_DOCUMENT_ROOT: public/
      PHP_FPM_PM_MAX_CHILDREN: 20
    volumes:
      - .:/var/www/html
    healthcheck:
      test: ["CMD", "php-fpm-healthcheck"]
```

Apache runs with the `mpm_event` MPM and sends the PHP requests to PHP-FPM, in the same container. The Apache
settings of the *apache* variant are available: `.htaccess` files, `APACHE_DOCUMENT_ROOT`, `APACHE_EXTENSION_*` and
`APACHE_EXTENSIONS` (see [Variants](variants.md#apache)).
`mpm_event`, `proxy` and `proxy_fcgi` are enabled instead of `mpm_prefork` and `mod_php`.

If Apache or PHP-FPM stops, the other one is stopped too and the container exits with an error, so that your
orchestrator can restart it. On `docker stop`, both are stopped gracefully: requests being processed are completed.

### Advantages over the apache variant

With `mod_php` (the *apache* variant), Apache must use `mpm_prefork`: each connection holds a whole Apache process
embedding PHP, including idle keep-alive connections (a browser opens up to 6) and static files. With PHP-FPM, Apache
keeps the connections with a few threads, and only PHP requests reach the PHP workers.

Both reach the same CPU-bound capacity when nothing holds a connection (fast clients, or a reverse proxy in front of
the container). As soon as connections live longer than PHP requests, the *fpm* variant serves more
([benchmark](../benchmarks/capacity/README.md), 1 CPU): **+63% with HTTPS** terminated in the container (keep-alive
and HTTP/2), and **+16% to +29% of pages served during a traffic peak** behind a reverse proxy, without the risk of
running out of memory with many mod_php processes.

Other differences:

- the number of PHP workers is set independently of the number of connections (see below);
- HTTP/2 can be enabled (`APACHE_EXTENSION_HTTP2=1`): it is not served with `mpm_prefork`;
- [`fastcgi_finish_request()`](https://www.php.net/manual/en/function.fastcgi-finish-request.php) is available: the
  response is sent to the client, and the script can go on with slower tasks.

## Your own web server

PHP-FPM listens on port `9000` of the container. The web server must send the PHP requests to it, with the path of
the script **in the PHP container** (`SCRIPT_FILENAME`), and serve the static files itself: both containers need the
files of the application. Example with nginx:

```yml
services:
  php:
    image: thecodingmachine/php:8.4-v5-fpm
    volumes:
      - .:/var/www/html
  web:
    image: nginx:stable
    ports:
      - "80:80"
    volumes:
      - .:/var/www/html:ro
      - ./nginx.conf:/etc/nginx/conf.d/default.conf:ro
```

```nginx
server {
    listen 80;
    root /var/www/html/public;
    index index.php;

    location / {
        try_files $uri /index.php$is_args$args;
    }

    location ~ \.php$ {
        try_files $uri =404;
        fastcgi_pass php:9000;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
    }
}
```

## Application directory

The application does not have to be in `/var/www/html`: PHP-FPM runs the script whose path it receives from the web
server. Mount the application in another directory and give its path to the web server: `APACHE_DOCUMENT_ROOT` with
the built-in Apache (an absolute path), the `root` of nginx... Also set the working directory: by default, the
commands run with the owner of the working directory (see [Permissions](advanced.md#permissions)).

```yml
services:
  app:
    image: thecodingmachine/php:8.4-v5-fpm
    working_dir: /var/www
    environment:
      PHP_FPM_WEB_SERVER: apache
      APACHE_DOCUMENT_ROOT: /var/www/public
    volumes:
      - .:/var/www
```

## Several pools

The `www` pool of PHP-FPM processes all the PHP requests. Another pool can process some of them with its own
settings: number of workers, `php.ini` parameters... for instance the back office of a WordPress site, with more
memory and fewer workers. Add a pool file listening on another port:

```ini
; admin-pool.conf
[admin]
listen = 9001
; Same user as the www pool (with the built-in Apache, the PHP-FPM master process runs as root)
user = ${APACHE_RUN_USER}
group = ${APACHE_RUN_GROUP}
clear_env = no
catch_workers_output = yes
decorate_workers_output = no
pm = ondemand
pm.max_children = 2
php_admin_value[memory_limit] = 512M
```

With the built-in Apache, send the requests of the back office to this pool:

```apache
# apache-admin-pool.conf
<LocationMatch "^/wp-admin/.*\.php$">
    <If "-f %{REQUEST_FILENAME}">
        SetHandler "proxy:fcgi://127.0.0.1:9001"
    </If>
</LocationMatch>
```

```yml
services:
  app:
    image: thecodingmachine/php:8.4-v5-fpm
    environment:
      PHP_FPM_WEB_SERVER: apache
    volumes:
      - .:/var/www/html
      - ./admin-pool.conf:/etc/php/8.4/fpm/pool.d/admin.conf:ro
      - ./apache-admin-pool.conf:/etc/apache2/conf-enabled/admin-pool.conf:ro
```

With your own web server, send these requests to the port of the pool (`fastcgi_pass php:9001;` in a `location` of
nginx).

## Constraints of PHP-FPM

### Number of workers and memory

PHP requests are processed by a fixed pool of PHP-FPM workers: **at most `PHP_FPM_PM_MAX_CHILDREN` requests are
processed at the same time** (`10` by default). The other ones wait for a free worker.
With the *apache* variant, this limit is the number of Apache processes (`APACHE_MAX_REQUEST_WORKERS`, `20`), which
also serve the static files.

`memory_limit` (`PHP_INI_MEMORY_LIMIT`) is a limit per request: in the worst case, PHP uses
`PHP_FPM_PM_MAX_CHILDREN` x `memory_limit`. Size the number of workers for the memory of the container, for instance
with a 1 GiB container and a `memory_limit` of `128M`, at most ~6 workers if every request may reach the limit, more if
your requests use much less memory (check the memory of the workers with `docker stats` or `ps`).

| Environment variable           | Default   | Description |
|--------------------------------|-----------|-------------|
| `PHP_FPM_PM`                   | `dynamic` | `static` (fixed number of workers), `dynamic` or `ondemand` |
| `PHP_FPM_PM_MAX_CHILDREN`      | `10`      | Maximum number of workers (requests processed at the same time) |
| `PHP_FPM_PM_START_SERVERS`     | `4`       | Workers started with PHP-FPM (`dynamic`) |
| `PHP_FPM_PM_MIN_SPARE_SERVERS` | `2`       | Minimum number of idle workers (`dynamic`) |
| `PHP_FPM_PM_MAX_SPARE_SERVERS` | `6`       | Maximum number of idle workers (`dynamic`) |
| `PHP_FPM_PM_MAX_REQUESTS`      | `0`       | Requests processed by a worker before it is restarted (`0`: never), useful if your application leaks memory |

See the [PHP-FPM documentation](https://www.php.net/manual/en/install.fpm.configuration.php) for the details, and the
[tuning simulator](tuning/) to choose the number of workers for your application, for instance an
[API with 1000 users](tuning/#app=api&users=1000&front=proxy).

### Execution time

`max_execution_time` (`PHP_INI_MAX_EXECUTION_TIME`) and `set_time_limit()` work as with `mod_php` (on Linux, the time
spent in system calls, database queries or `sleep()` is not counted).

But the web server in front of PHP-FPM has its own timeout: if PHP does not answer within
`APACHE_PROXY_TIMEOUT` seconds (`300` by default), the built-in Apache answers with a `504 Gateway Timeout` error,
even with `set_time_limit(0)`. With nginx, the default `fastcgi_read_timeout` is 60 seconds. Long tasks should run in
a CLI command, a [cron job](processes.md#cron-jobs) or a queue worker.

### `php_value` in `.htaccess`

`php_value` and `php_flag` directives are `mod_php` directives: in a `.htaccess` file, Apache answers with a `500`
error. Use the `PHP_INI_*` environment variables, or a [`.user.ini` file](https://www.php.net/manual/en/configuration.file.per-user.php)
(read by PHP-FPM, cached for 5 minutes).

### Other differences

- Environment variables are read by PHP-FPM: they are available in `getenv()` and `$_SERVER`, but no longer exposed
  to Apache (`PassEnv`).
- The `Authorization` header is forwarded to PHP (`PHP_AUTH_USER`, `HTTP_AUTHORIZATION`...).
- PHP files that do not exist get an Apache `404` error.
- The PHP-FPM workers run with the Apache user (`docker` by default), like `mod_php`.
- The PHP-FPM access log is disabled with the built-in Apache: Apache already writes one.

## Migrating from the apache variant

1. Use the *fpm* image and enable the built-in Apache: `thecodingmachine/php:8.4-v5-apache` becomes
   `thecodingmachine/php:8.4-v5-fpm` with `PHP_FPM_WEB_SERVER=apache`. Keep your `APACHE_*` variables.
2. Set the number of PHP workers (`PHP_FPM_PM_MAX_CHILDREN`) for your traffic and your memory (see above, or the
   [tuning simulator](tuning/)).
3. Replace the `php_value` / `php_flag` directives of your `.htaccess` files.
4. Optionally, use `php-fpm-healthcheck` as healthcheck (Docker) or probe (Kubernetes).
