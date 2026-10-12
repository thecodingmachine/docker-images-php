# Processes: startup commands, cron jobs and daemons

On each start, the entrypoint of the image:

1. configures PHP (extensions, `php.ini`), Apache, Composer and the locales from the environment variables;
2. runs the [startup commands](#startup-commands);
3. runs the main command (the Docker *command*: Apache, PHP-FPM or your CLI command), along with
   [Supercronic](#cron-jobs) and the [daemons](#daemons) if any.

## Startup commands

The `STARTUP_COMMAND_<suffix>` variables are run in the order of their suffix before the main command, for instance
to install dependencies or to apply database migrations:

```bash
STARTUP_COMMAND_1=composer install
STARTUP_COMMAND_2=vendor/bin/doctrine orm:schema-tool:update
```

They are run by the `docker` user (see [Permissions](advanced.md#permissions)), or by the user of ID `UID` if this
variable is set (e.g. `UID=0` for `root`). The container stops if a command fails.

As an alternative, an executable file mounted at `/etc/container/startup.sh` is run before these commands:

```bash
$ docker run --rm -v "$PWD":/usr/src/app -v "$PWD/my-startup-script.sh":/etc/container/startup.sh \
    thecodingmachine/php:8.4-v5-cli php your-script.php
```

## Cron jobs

The `CRON_SCHEDULE`, `CRON_COMMAND` and (optionally) `CRON_USER` variables define a cron job:

```bash
# The user that runs the job (defaults to root)
CRON_USER=root
# The schedule (here: every minute)
CRON_SCHEDULE=* * * * *
# The command
CRON_COMMAND=vendor/bin/console do:stuff
```

For several jobs, add the same suffix to the variables of each job:

```bash
CRON_USER_1=root
CRON_SCHEDULE_1=* * * * *
CRON_COMMAND_1=vendor/bin/console do:stuff

CRON_USER_2=www-data
CRON_SCHEDULE_2=0 3 * * *
CRON_COMMAND_2=vendor/bin/console other:stuff
```

The output of the jobs is sent to the Docker logs.

The containers run in the UTC timezone: the `TZ` variable changes it.

```bash
# Run this job at 1 am, Paris time
TZ=Europe/Paris
CRON_SCHEDULE_1=0 1 * * *
CRON_COMMAND_1=vendor/bin/console do:stuff
```

The jobs are run by [Supercronic](https://github.com/aptible/supercronic), a cron replacement designed for containers.
It is **installed by default in the fat images**. With a slim image, install it with an ARG before the `FROM`:

```Dockerfile
ARG INSTALL_CRON=1
FROM thecodingmachine/php:8.4-v5-slim-apache
```

`SUPERCRONIC_OPTIONS` passes options to Supercronic. For instance, by default, a job is not started again while its
previous run is not finished; `-overlapping` allows it:

```bash
SUPERCRONIC_OPTIONS=-overlapping -debug
```

See the [Supercronic documentation](https://github.com/aptible/supercronic/blob/master/README.md) for the other
options.

Supercronic is supervised like the [daemons](#daemons): if it exits, the container stops.

**Important**: the jobs run in every container started from your configuration. If you scale your application to
several containers, a job that must run once per application (not once per container) belongs to your orchestrator
(e.g. a Kubernetes CronJob) or to a dedicated container.

## Daemons

**Prefer one container per process.** For instance, run a Laravel queue worker in its own container (the *cli* image,
with `php artisan queue:work` as command) rather than in the Apache container: Docker and your orchestrator can then
restart, scale, limit and monitor each process.

When a separate container is not an option, the `DAEMON_COMMAND_<suffix>` variables start long-running processes along
with the main command. They are run by the `docker` user (see [Permissions](advanced.md#permissions)), or by the user
set in the `DAEMON_USER_<suffix>` variable with the same suffix (a user name or an ID):

```bash
DAEMON_COMMAND_1=php artisan queue:work
DAEMON_COMMAND_2=php artisan horizon
DAEMON_USER_2=www-data
```

A command that finishes, like `composer install`, is a [startup command](#startup-commands), not a daemon: its end
would stop the container.

These processes are not restarted: **as soon as one of them (or the main command) exits, the other ones are stopped
and the container stops** with the exit code of this process. Use a restart policy (e.g. `restart: unless-stopped`)
to restart the container.

When the container stops (`docker stop` or a process that exited), Apache and PHP-FPM are stopped gracefully (the
running requests are completed), and the other processes (another main command, the daemons and Supercronic) receive
`SIGTERM`.
