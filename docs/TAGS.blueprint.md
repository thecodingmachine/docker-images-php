[<- Main documentation](../README.md)

{{ $image := .Orbit.Images }}
# Tags

## Maintenance support

This project try to keep old versions active on ours build but : 
* You may experience some issue with them (less testing, and it's more difficult to support)
* In next version (V5), these images may have less default features (probably the fat version maybe no more updated or less than supported one)
* If you want to ensure more support on deprecated one, you can send your PR and/or open an issue to suggest solutions

So it's only to allow you to upgrade to the next supported version an old project.  

### PHP versions

* [PHP 7.2 and 7.3 are end of life](https://www.php.net/supported-versions.php)
* [PHP 7.4 still only supported for security version](https://www.php.net/supported-versions.php) until 1 jan 2023

### Node versions

* [Node 10 and 12 are end of life](https://nodejs.org/en/about/releases/)
* Old version of node will be removed even in same major version of these repository (but still available with `ARG NODE_VERSION=any.version.you.need`)

## Minor versions

Note: we also tag patch releases of PHP versions. So you can specify a specific patch release using thecodingmachine/php:**8.0.2**-v4-cli for instance.
However, unless you have a **very specific need** (for instance if the latest patch release of PHP introduced regressions), believe you have no valid reason to ask explicitly for 8.0.2 for instance.
When 8.0.3 is out, you certainly want to upgrade automatically to this patch release since patch releases contain only bugfixes.
Also, we automatically rebuild X.Y images every week, but only the latest X.Y.Z patch release gets a rebuild. The other patch releases are frozen in time and will contain bugs and security issues. So use those with great care.

[Major].[minor] images are automatically updated when a new patch version of PHP is released, so the PHP 7.4 image will always contain
the most up-to-date version of the PHP 7.4.x branch.

## Built versions

It may happen any outage (rarely) because of one deploy is wrongly tested and there is a breaking change on dependencies for one version. If it's happen, you can use the previous `rc` tag
You can look for this tagged `rc` tags with dockerhub platform. Per example [look for fat cli version of php8.1 with node16](https://hub.docker.com/r/thecodingmachine/php/tags?page=1&name=rc%258.1%25v4-cli-node16). Each `rc` is related to the workflow id in GitHub action so more the id height, more this image is recent. 

## All Tags
{{ $versions := list "8.1" "8.0" "7.4" "7.3" "7.2" }}
{{ $nodeVersions := list "10" "12" "14" "16" }}

| Name                                                                    | PHP version                  | type |variant | NodeJS version  | Size 
|-------------------------------------------------------------------------|------------------------------|------|--------|-----------------|------
{{range $phpV := $versions}}| [thecodingmachine/php:{{ $phpV }}-v4-apache](https://github.com/thecodingmachine/docker-images-php/blob/v4/Dockerfile.apache)                                        | `{{ $phpV }}.x` | fat  | apache | *N/A*            | [![](https://images.microbadger.com/badges/image/thecodingmachine/php:{{ $phpV }}-v4-apache.svg)](https://microbadger.com/images/thecodingmachine/php:{{ $phpV }}-v4-apache)
{{range $nodeV := $nodeVersions}}| [thecodingmachine/php:{{ $phpV }}-v4-apache-node{{ $nodeV }}](https://github.com/thecodingmachine/docker-images-php/blob/v4/Dockerfile.apache.node{{ $nodeV }}) | `{{ $phpV }}.x` | fat  | apache | `{{ $nodeV }}.x` | [![](https://images.microbadger.com/badges/image/thecodingmachine/php:{{ $phpV }}-v4-apache-node{{ $nodeV }}.svg)](https://microbadger.com/images/thecodingmachine/php:{{ $phpV }}-v4-apache-node{{ $nodeV }})
{{ end }}| [thecodingmachine/php:{{ $phpV }}-v4-fpm](https://github.com/thecodingmachine/docker-images-php/blob/v4/Dockerfile.fpm)                                                                 | `{{ $phpV }}.x` | fat  | fpm    | *N/A*            | [![](https://images.microbadger.com/badges/image/thecodingmachine/php:{{ $phpV }}-v4-fpm.svg)](https://microbadger.com/images/thecodingmachine/php:{{ $phpV }}-v4-fpm)
{{range $nodeV := $nodeVersions}}| [thecodingmachine/php:{{ $phpV }}-v4-fpm-node{{ $nodeV }}](https://github.com/thecodingmachine/docker-images-php/blob/v4/Dockerfile.fpm.node{{ $nodeV }})       | `{{ $phpV }}.x` | fat  | fpm    | `{{ $nodeV }}.x` | [![](https://images.microbadger.com/badges/image/thecodingmachine/php:{{ $phpV }}-v4-fpm-node{{ $nodeV }}.svg)](https://microbadger.com/images/thecodingmachine/php:{{ $phpV }}-v4-fpm-node{{ $nodeV }})
{{ end }}| [thecodingmachine/php:{{ $phpV }}-v4-cli](https://github.com/thecodingmachine/docker-images-php/blob/v4/Dockerfile.cli)                                                                 | `{{ $phpV }}.x` | fat  | cli    | *N/A*            | [![](https://images.microbadger.com/badges/image/thecodingmachine/php:{{ $phpV }}-v4-cli.svg)](https://microbadger.com/images/thecodingmachine/php:{{ $phpV }}-v4-cli)
{{range $nodeV := $nodeVersions}}| [thecodingmachine/php:{{ $phpV }}-v4-cli-node{{ $nodeV }}](https://github.com/thecodingmachine/docker-images-php/blob/v4/Dockerfile.cli.node{{ $nodeV }})       | `{{ $phpV }}.x` | fat  | cli    | `{{ $nodeV }}.x` | [![](https://images.microbadger.com/badges/image/thecodingmachine/php:{{ $phpV }}-v4-cli-node{{ $nodeV }}.svg)](https://microbadger.com/images/thecodingmachine/php:{{ $phpV }}-v4-cli-node{{ $nodeV }})
{{ end }}| [thecodingmachine/php:{{ $phpV }}-v4-slim-apache](https://github.com/thecodingmachine/docker-images-php/blob/v4/Dockerfile.slim.apache)                                                 | `{{ $phpV }}.x` | slim | apache | *N/A*            | [![](https://images.microbadger.com/badges/image/thecodingmachine/php:{{ $phpV }}-v4-slim-apache.svg)](https://microbadger.com/images/thecodingmachine/php:{{ $phpV }}-v4-slim-apache)
| [thecodingmachine/php:{{ $phpV }}-v4-slim-fpm](https://github.com/thecodingmachine/docker-images-php/blob/v4/Dockerfile.slim.fpm)                                                                | `{{ $phpV }}.x` | slim | fpm    | *N/A*            | [![](https://images.microbadger.com/badges/image/thecodingmachine/php:{{ $phpV }}-v4-slim-fpm.svg)](https://microbadger.com/images/thecodingmachine/php:{{ $phpV }}-v4-slim-fpm)
| [thecodingmachine/php:{{ $phpV }}-v4-slim-cli](https://github.com/thecodingmachine/docker-images-php/blob/v4/Dockerfile.slim.cli)                                                                | `{{ $phpV }}.x` | slim | cli    | *N/A*            | [![](https://images.microbadger.com/badges/image/thecodingmachine/php:{{ $phpV }}-v4-slim-cli.svg)](https://microbadger.com/images/thecodingmachine/php:{{ $phpV }}-v4-slim-cli)
{{end}}