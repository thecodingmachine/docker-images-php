# Debugging and profiling

## Xdebug

Enable the Xdebug extension:

```bash
PHP_EXTENSION_XDEBUG=1
```

The image then configures Xdebug to connect back to your Docker host:

- `xdebug.mode` is set to `debug`
- on Linux, `xdebug.client_host` is the IP of your Docker gateway
- on Windows and macOS, `xdebug.client_host` is the IP of
  [`host.docker.internal`](https://docs.docker.com/desktop/features/networking/#use-cases-and-workarounds)
  (or `docker.for.mac.localhost` on old Docker versions)

To debug from inside the container (for instance with [VSCode devcontainers](https://code.visualstudio.com/docs/remote/containers)),
set `xdebug.client_host` yourself with the `XDEBUG_CLIENT_HOST` variable:

```bash
XDEBUG_CLIENT_HOST=127.0.0.1
```

The other Xdebug parameters can be set like any `php.ini` parameter (see [PHP configuration](php-configuration.md)),
e.g. `PHP_INI_XDEBUG__START_WITH_REQUEST=yes`.

## Blackfire

The fat images come with the [Blackfire](https://blackfire.io) PHP probe and CLI. Enable the probe with:

```bash
PHP_EXTENSION_BLACKFIRE=1
```

The probe expects the Blackfire agent to run in another container, reachable with the `blackfire` host name:

```yml
services:
  php:
    image: thecodingmachine/php:8.4-v5-apache
    ports:
      - "80:80"
    environment:
      PHP_EXTENSION_BLACKFIRE: 1
  blackfire:
    image: blackfire/blackfire
    environment:
      # Exposes the BLACKFIRE_SERVER_ID and BLACKFIRE_SERVER_TOKEN environment variables of the host
      - BLACKFIRE_SERVER_ID
      - BLACKFIRE_SERVER_TOKEN
```

If the agent has another host name, set it with the `BLACKFIRE_AGENT` variable:

```yml
services:
  php:
    image: thecodingmachine/php:8.4-v5-apache
    environment:
      PHP_EXTENSION_BLACKFIRE: 1
      BLACKFIRE_AGENT: myblackfire
  myblackfire:
    image: blackfire/blackfire
    # ...
```

See the [Blackfire Docker documentation](https://blackfire.io/docs/integrations/docker) for more information.

With a slim image, add `blackfire` to the [`PHP_EXTENSIONS` ARG](extensions.md#compiling-extensions-in-the-slim-images).
The probe version 2 is installed by default; the `BLACKFIRE_VERSION=1` build ARG installs the version 1, which has
known security issues.
