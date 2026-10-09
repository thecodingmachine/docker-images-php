# Benchmark: `apache` (mod_php) vs `fpm` with its built-in Apache

Both variants run the same application with their default Apache settings and the same resources (2 CPUs, 2 GB),
and receive exactly the same load: a constant number of pages per second. A page is a PHP request (~3 ms of CPU and
20 ms of I/O) and 10 static assets, like a browser. A variant handles a rate when its p95 stays under 100 ms and its
p99 under 1 s, without error.

## Results (PHP 8.4, amd64)

| | `apache` (mod_php) | `fpm` + built-in Apache |
|---|---|---|
| Pages per second handled | 10 | **30** |
| PHP requests per second handled (no assets) | < 100 | **200** |
| Memory | 280-385 MiB | **80-100 MiB** |

The `fpm` variant serves **2 to 3 times more traffic with 4 times less memory**.

With `mod_php`, every connection holds an Apache process embedding PHP, including idle keep-alive connections (a
browser opens up to 6): from 15 pages/s the 150 processes are exhausted and requests wait for up to 30 s, while the
CPU is almost idle. With PHP-FPM, Apache (`mpm_event`) keeps the connections with a few threads and only PHP
requests use the 20 PHP workers.

Single run on a developer machine: the orders of magnitude are reliable, not the exact values.

## Running it

Requires Docker only ([k6](https://k6.io/) runs in a container):

```bash
./run.sh 8.4
```
