# Contributing

Submit your pull requests to the `v5` branch.

## Generated files

The `Dockerfile.*` files, `docker-bake.hcl` and `README.md` are generated from the templates of the `utils` directory
with [Orbit](https://github.com/gulien/orbit): edit `utils/Dockerfile.*.blueprint`, `utils/docker-bake.blueprint.hcl`
or `utils/README.blueprint.md`, then run:

```bash
$ make blueprint
```

The pages of the `docs` directory are not generated: edit them directly.

## Building and testing

The tests use [bash_unit](https://github.com/pgrange/bash_unit) (see the [test suite](../tests-suite/README.md)).
Build and test a PHP version (*cli*, *apache* and *fpm* variants):

```bash
$ make test-8.4
```

`make test-quick` builds and tests the *cli* variant of the maintained PHP versions, without NodeJS.

To test images already built, run the test suite directly:

```bash
$ PHP_VERSION=8.4 BRANCH=v5 VARIANT=apache ./tests-suite/bash_unit -f tap ./tests-suite/*.sh
```

The variables of [`tests-suite/config`](../tests-suite/config) select the images to test, e.g. `TAG_PREFIX` (images
built with `TAG_PREFIX=mytest- docker buildx bake ...`) or `PLATFORM` (e.g. `linux/arm64` with QEMU).

**Apple Silicon:** the file system of macOS manages the users and permissions differently: the permission tests of
a `linux/arm64` image can fail on a Mac, while the images work as expected. Run the tests in a `linux/arm64` virtual
machine instead.

## Adding a PHP or NodeJS version

- `utils/README.blueprint.md`: the version lists of the "Images" section
- `utils/docker-bake.blueprint.hcl`: the build targets
- `.github/workflows/workflow.yml` (maintained versions) or `.github/workflows/legacy-v5.yml` (non-maintained
  versions): the CI matrix
- `extensions/<PHP version>`: the extensions available for this PHP version
