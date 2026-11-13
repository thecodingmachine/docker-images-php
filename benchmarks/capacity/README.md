# Benchmark: capacity of mod_php and PHP-FPM on one CPU

How many pages per second can one container serve, with the `apache` variant (Apache `mpm_prefork` + mod_php) and the
`fpm` variant (built-in Apache `mpm_event` + PHP-FPM, or nginx + PHP-FPM)? And which settings get there?

These measures give the tuned settings proposed as defaults for the v6 images and calibrate the [tuning simulator](https://thecodingmachine.github.io/docker-images-php/tuning/).

## Summary

- **The v5 defaults of the `apache` variant break under a real load**: keep-alive with browsers holds all the
  mod_php processes (less than 3 pages/s with 3% of CPU), and a traffic peak with 48 MB pages spawns up to 150
  processes that exhaust the memory (208 processes killed, 30% of errors, 2 pages/s served).
- **Tuned, mod_php and PHP-FPM reach the same CPU-bound capacity** when nothing holds a connection: fast clients in
  plain HTTP, or behind a reverse proxy.
- **PHP-FPM wins as soon as connections live longer than PHP**: +63% with HTTPS terminated in the container, keep-alive
  and HTTP/2 for the browsers, and +16% to +29% of pages served during a traffic peak behind a reverse proxy.
- Tuned settings (see [Tuned settings](#tuned-settings)), set with environment variables in v5 and proposed as
  defaults for v6: `apache` variant without keep-alive and with a fixed pool of 30 processes; `fpm` variant with 10 PHP
  workers and a larger `mpm_event`.

## Method

- **Server:** one container, `--cpuset-cpus` = 1 logical CPU, `--memory=2g`. nginx shares the CPU and the network of
  the PHP-FPM container when used. PHP 8.4.
- **Machine:** Intel i7-10750H with turbo disabled (fixed 2.6 GHz, close to a cloud vCPU), on mains power.
- **Application** ([app](app)): Symfony 7.4 + Twig, `APP_ENV=prod`, classmap-authoritative autoload,
  `opcache.validate_timestamps=0`. The page decodes a 1000-product JSON catalog (470 KB), filters, sorts, renders 100
  products with Twig (53 KB of HTML) and writes a JSON file on disk. About 8 ms of CPU.
  `IO_WAIT_MS` adds a wait (like a database), `PAGE_MEM_MB` allocates memory.
- **Load** ([page.js](bench/page.js), k6, open model): a page = the PHP request + 10 CSS files of 40 KB fetched in
  parallel, then a think time with the connections kept open (like a browser). 10 s ramp, then 30 s (60 s behind the
  proxy) at the target rate.
- **A rate passes** when page p95 < 500 ms and p99 < 1 s (1 s and 2 s with the client latencies of the proxy
  scenario), errors < 1% and no dropped page.
- **Search:** steps until the first failure, then bisection down to 2-3 pages/s, fresh container for every run.
- **Validity:** a limit only counts if the server CPU (or memory) is saturated when it fails; a failure with idle
  CPU points to a bottleneck in the settings.
- **Noise:** about ±5% (the same configuration measured twice gave 75 and 81 pages/s).

## Results

### Plain HTTP, clients on the local network

Think time 1 s, browsers keep their connections.

| Configuration | Limit (pass / fail, pages/s) | CPU at failure | Memory |
|---|---|---|---|
| `apache`, v5 defaults (keep-alive, dynamic pool up to 150) | < 3 | 3% | 143 MiB |
| `apache`, keep-alive off + fixed pool of 30 ([apache-tuned](configs/apache-tuned)) | 81 / 84 | 103% | 128 MiB |
| `fpm` + Apache, v5 defaults (5 workers) | 37 / 40 | 55% | 79 MiB |
| `fpm` + Apache, 10 workers, default `mpm_event` | 37 / 40 | 49-53% | 82 MiB |
| `fpm` + Apache, 10 workers, larger `mpm_event` ([fpm-tuned](configs/fpm-tuned)) | 81 / 84 | 102% | 148 MiB |
| nginx + `fpm` | 93 / 96 | 100% | 47 MiB |
| **`apache`, tuned settings as image defaults** | **75 / 78** | 93-101% | 129 MiB |
| **`fpm` + Apache, tuned settings as image defaults** | **81 / 84** | 101% | 187 MiB |

- With keep-alive, each idle browser connection holds a mod_php process: the 150 processes are exhausted with an idle
  CPU.
- The default `mpm_event` of Ubuntu (150 threads, 25 per process) limits the number of connections of the browsers.
- Without `ListenBacklog 4096`, an overload of mod_php makes the kernel drop connections ("SYN flooding") and the
  throughput collapses to 11-15 pages/s with 3-4% of errors.
- nginx serves the static files for less CPU than Apache.

### HTTPS terminated in the container

ECDSA P-256 certificate, TLS 1.3.

| Configuration | Limit (pages/s) | vs plain HTTP |
|---|---|---|
| mod_php, keep-alive off, HTTP/1.1 | 46 / 48 | −43% |
| Apache + PHP-FPM, HTTP/2 | 75 / 78 | −7% |
| nginx + PHP-FPM, HTTP/2 | 84 / 87 | −10% |

Without keep-alive, mod_php makes a TCP + TLS handshake for each of the 11 requests of a page; PHP-FPM keeps the
connection and multiplexes the page on it with HTTP/2. With keep-alive, mod_php is back to the first case (all its
processes held by idle connections).

### Behind a reverse proxy, European clients

The most common production setup: Traefik (on its own CPU) terminates the connections of the browsers and forwards
plain HTTP to the container. Each page waits 30 ms (database) and uses 16 MB. The clients are a mix of 50% fiber
(15 ms of round trip), 30% cable / DSL (30 ms) and 20% mobile (50 ms), emulated with `netem`; think time 5 s.

| Configuration | Limit (pages/s) | At 30 pages/s (overload): p95, memory |
|---|---|---|
| `apache`, v5 defaults | 28 / 30 | 36 s, 1372 MiB |
| `apache`, keep-alive off + fixed pool of 30 | 27 / 28 | 6.3 s, 351 MiB |
| `apache`, keep-alive on + fixed pool of 30 | 25 / 27 (p99 14 s) | 39 s, errors |
| `fpm` + Apache, v5 defaults | 27 / 28 | 7 s, 177 MiB |
| `fpm` + Apache, tuned | 27 / 28 | 4.6 s, 270 MiB |
| **`apache`, tuned settings as image defaults** | **27 / 28** | |
| **`fpm` + Apache, tuned settings as image defaults** | **28 / 30** | |

- Same capacity: the proxy keeps the browser connections, the container only sees short requests.
- With keep-alive, the proxy parks idle connections on the mod_php processes: near the limit, new connections wait
  for a free process (p99 of 14 s). Keep-alive must stay off for mod_php, even behind a proxy.
- The page uses 16 MB: touching this memory costs ~8 ms of CPU (page faults), hence a lower capacity than in the
  plain HTTP test.

### Traffic peak behind the reverse proxy

Same scenario, 60 s at about twice the capacity.

| Configuration | 16 MB pages, 55 pages/s: served, errors, memory | 48 MB pages, 40 pages/s: served, errors, memory |
|---|---|---|
| `apache`, v5 defaults | 22.2 pages/s, 3.6%, 1698 MiB | **2 pages/s, 30%, 2048 MiB, 208 processes killed (OOM)** |
| `apache`, keep-alive off + fixed pool of 30 | 21.8 pages/s, 0%, 364 MiB | 13.6 pages/s, 0%, 867 MiB |
| `fpm` + Apache, v5 defaults | 24.3 pages/s, 0.8%, 184 MiB | 16.7 pages/s, 1.4%, 330 MiB |
| `fpm` + Apache, tuned | **25.3 pages/s, 0%**, 556 MiB | **17.6 pages/s, 0%**, 686 MiB |

- With the v5 defaults, mod_php starts up to 150 processes: with 48 MB pages they need more than 2 GB, the kernel kills
  them and the container serves almost nothing.
- During a peak, PHP-FPM serves 16% (16 MB pages) to 29% (48 MB) more pages than tuned mod_php: its 10 workers share
  the CPU with less contention than 30 mod_php processes, and Apache serves the static files without waiting for a
  PHP process.

## Tuned settings

| | `apache` variant | `fpm` variant (built-in Apache) |
|---|---|---|
| `APACHE_KEEPALIVE` | `Off` (v5 default: `On`) | `On` |
| `APACHE_MAX_REQUEST_WORKERS` | `30`, fixed pool (v5 default: a dynamic pool up to `150`) | `1024` threads, 64 per process (v5 default: `150`, 25 per process) |
| `ListenBacklog` | `4096` (default: `511`) | `4096` |
| `PHP_FPM_PM_MAX_CHILDREN` | | `10` (v5 default: `5`), start `4`, spare `2`-`6` |

The v5 images keep their defaults: set `APACHE_KEEPALIVE`, `APACHE_MAX_REQUEST_WORKERS` and the `PHP_FPM_PM_*`
variables (the measured configurations are in [configs](configs)). These settings are a median for a typical
application on 1-2 CPUs: size them for your application with the
[tuning simulator](https://thecodingmachine.github.io/docker-images-php/tuning/).

## What is not covered

- More than one CPU per container, and pages much heavier in CPU.
- Slow uploads (forms, files) from mobile clients, long requests (exports, long polling).
- Clients connecting directly to the container over a high-latency network.

## Running it

Requires Docker only (k6, Traefik and the tools run in containers).

```bash
./bench/setup.sh                                   # application, data, certificate, netem image
# Limit search of configurations, one after the other: lane.sh <server CPU> <k6 CPUs> <configuration>...
STEP=25 PREC=3 ./bench/lane.sh 0 2,8 apache-tuned fpm-tuned
# Behind Traefik (on CPU 4), with the European client mix
(source bench/proxy.sh; PROXY_CPU=4 STEP=10 PREC=2 ./bench/lane.sh 0 2,8 apache-defaults fpm-defaults)
# Traffic peak: spike.sh <server CPU> <k6 CPUs> <rate> <label> <configuration>...
(source bench/proxy.sh; PROXY_CPU=4 ./bench/spike.sh 0 2,8 55 spike16 apache-tuned fpm-tuned)
```

- `IMAGE_TAG` (`8.4-v5`) and `REPO` select the image; the results are in `run/<configuration>/`.
- A configuration ([configs](configs)) holds `kind` (`apache`, `fpm-apache` or `nginx-fpm`) and optionally `env`,
  `mpm.conf`, `apache.conf`, `nginx.conf` and `tls`.
- Disable the turbo of the CPU (`echo 1 | sudo tee /sys/devices/system/cpu/intel_pstate/no_turbo`) and stay on mains
  power: the cost of a page changes with the frequency. Do not run more than two lanes at the same time.
