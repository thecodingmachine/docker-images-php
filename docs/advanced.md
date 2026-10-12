# Advanced features

## Permissions

The images limit the file permission issues that often arise with Docker.

The commands of a container usually run as `root`, so the files they create (e.g. by `composer install`) belong to
`root` on your host. The container and the host do not share their users: you might be logged in as `superdev`
(ID 1000) on your host while the container has no user with ID 1000.

The images contain a `docker` user. On startup, the entrypoint looks at the owner of the working directory
(`/var/www/html` for *apache* and *fpm*, `/usr/src/app` for *cli*) and **changes the ID of the `docker` user** to the
ID of this owner. The commands, Apache and PHP-FPM then run as `docker`:

- your PHP application can edit any file of your project;
- you can edit any file created by the container.

If this ID is already used by a system account of the image (e.g. `998`, used by `systemd-network` in the image and
often by the `gitlab-runner` user on CI hosts), this system account is moved to another ID: the commands are still run
by the `docker` user.

`DOCKER_USER` sets the user explicitly, with a user name of the image or an ID:

```bash
DOCKER_USER=1001
```

**In production**, Apache should not be allowed to edit the PHP files of your application: if an attacker can change
them through a security hole, they can run any PHP code. Run Apache as `www-data` (see
[Apache user](variants.md#apache-user)).

## NodeJS

The fat images have NodeJS variants (e.g. `thecodingmachine/php:8.4-v5-apache-node24`), see the
[list of images](../README.md#images).

With a slim image, the `NODE_VERSION` ARG installs NodeJS (with npm and yarn) during the build:

```Dockerfile
ARG NODE_VERSION=24
FROM thecodingmachine/php:8.4-v5-slim-apache
```

The `ARG NODE_VERSION` instruction must be written before the `FROM`. This is not a typo.

The binaries of `node_modules/.bin` and of Composer (`vendor/bin`, global binaries) can be run without their path,
including with `docker exec` / `docker compose exec` (e.g. `docker compose exec app phpstan`).

## Composer version

The images come with the latest Composer version. `COMPOSER_VERSION` installs another one: an exact version (e.g.
`2.4.4`) or a channel (`1`, `2`, or `2.2` for the LTS version).

```bash
COMPOSER_VERSION=2.4.4
```

The version is installed when the container starts (this requires a network access). With a slim image, install it
during the build instead, with an ARG before the `FROM`:

```Dockerfile
ARG COMPOSER_VERSION=2.4.4
FROM thecodingmachine/php:8.4-v5-slim-apache
```

## Locales

Only the `C`, `C.UTF-8` and `POSIX` locales are available by default. `LOCALES` lists the locales to generate when
the container starts:

```bash
LOCALES=fr_FR.UTF-8 de_DE.UTF-8
# Optional: the default locale of the intl extension
PHP_INI_INTL__DEFAULT_LOCALE=fr_FR.UTF-8
```

The locales tools are **installed by default in the fat images**. With a slim image, install them with an ARG before
the `FROM`:

```Dockerfile
ARG INSTALL_LOCALES=1
FROM thecodingmachine/php:8.4-v5-slim-apache
```

## SSH private keys

If your project depends on a [package stored in a private Git repository](https://getcomposer.org/doc/05-repositories.md#using-private-repositories),
`composer install` needs your SSH private key.

**In development**, mount your keys in the container:

```yml
services:
  my_app:
    image: thecodingmachine/php:8.4-v5-apache
    volumes:
      - ~/.ssh:/home/docker/.ssh
```

**In a Dockerfile**, pass the key and the signature of the server (`ssh-keyscan myserver.com`) as build arguments:

```Dockerfile
FROM thecodingmachine/php:8.4-v5-apache

ARG SSH_PRIVATE_KEY
ARG SSH_KNOWN_HOSTS

RUN ssh-add <(echo "$SSH_PRIVATE_KEY")
RUN echo "$SSH_KNOWN_HOSTS" >> ~/.ssh/known_hosts
```

```bash
$ docker build -t my_image --build-arg SSH_PRIVATE_KEY="$SSH_PRIVATE_KEY" --build-arg SSH_KNOWN_HOSTS="$SSH_KNOWN_HOSTS" .
```

Beware: the build arguments are visible in the image history. Prefer
[build secrets](https://docs.docker.com/build/building/secrets/) for an image you distribute.

## Kubernetes

The entrypoint uses `sudo`: the `docker` user needs to edit the PHP configuration as `root`. The Kubernetes
`allowPrivilegeEscalation: false` security setting forbids `sudo` and breaks the image, with this message in the logs:

```
sudo: effective uid is not 0, is /usr/bin/sudo on a file system with the 'nosuid' option set or an NFS file system without root privileges?
```

Never set this option to `false`:

```yml
apiVersion: v1
kind: Pod
# ...
spec:
  containers:
  - name: foobar
    image: thecodingmachine/php:8.4-v5-apache
    securityContext:
      allowPrivilegeEscalation: true # never use "false" here
```

If your cluster forbids binding the ports below 1024, see [Apache ports](variants.md#ports).
