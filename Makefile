SHELL=/bin/bash

blueprint: ## Generate all blueprints file
	@if ! type orbit >/dev/null 2>&1; then echo "Missing orbit dependency, please install from https://github.com/gulien/orbit/"; exit 1; fi
	orbit run generate

test-latest: test-8.5 ## Test the latest build only

_test-prerequisites: blueprint
	docker pull ubuntu:20.04

test-hot:  ## Test 7.4, 8.0 and 8.1 quickly
	docker buildx bake --load \
    		--set "*.platform=$(uname -p)" \
    		php80-slim-cli php80-cli
	docker run --rm -it docker.io/thecodingmachine/php:8.0-v5-cli php -v
test-legacy-quick:  ## Test 7.4, 8.0 and 8.1 quickly
	VERSION=7.4 VARIANT=cli $(MAKE) _test-version-quick
	VERSION=8.0 VARIANT=cli $(MAKE) _test-version-quick
	VERSION=8.1 VARIANT=cli $(MAKE) _test-version-quick
test-quick:  ## Test 8.2, 8.3, 8.4 and 8.5 quickly
	VERSION=8.2 VARIANT=cli $(MAKE) _test-version-quick
	VERSION=8.3 VARIANT=cli $(MAKE) _test-version-quick
	VERSION=8.4 VARIANT=cli $(MAKE) _test-version-quick
	VERSION=8.5 VARIANT=cli $(MAKE) _test-version-quick

test-8.3:  ## Test php8.3 build only
	VERSION=8.3 VARIANT=cli $(MAKE) _test-version
	VERSION=8.3 VARIANT=apache $(MAKE) _test-version
	VERSION=8.3 VARIANT=fpm $(MAKE) _test-version

test-8.2:  ## Test php8.2 build only
	VERSION=8.2 VARIANT=cli $(MAKE) _test-version
	VERSION=8.2 VARIANT=apache $(MAKE) _test-version
	VERSION=8.2 VARIANT=fpm $(MAKE) _test-version

test-8.1:  ## Test php8.1 build only
	VERSION=8.1 VARIANT=cli $(MAKE) _test-version
	VERSION=8.1 VARIANT=apache $(MAKE) _test-version
	VERSION=8.1 VARIANT=fpm $(MAKE) _test-version

test-8.5:  ## Test php8.5 build only
	VERSION=8.5 VARIANT=cli $(MAKE) _test-version
	VERSION=8.5 VARIANT=apache $(MAKE) _test-version
	VERSION=8.5 VARIANT=fpm $(MAKE) _test-version

test-8.4:  ## Test php8.4 build only
	VERSION=8.4 VARIANT=cli $(MAKE) _test-version
	VERSION=8.4 VARIANT=apache $(MAKE) _test-version
	VERSION=8.4 VARIANT=fpm $(MAKE) _test-version

test-node:  ## Test node builds only
	VERSION=8.4 VARIANT=cli NODE=18 $(MAKE) _test-node
	VERSION=8.4 VARIANT=cli NODE=20 $(MAKE) _test-node
	VERSION=8.4 VARIANT=cli NODE=22 $(MAKE) _test-node

_test-node: _test-prerequisites ## Test node for VERSION="" and VARIANT=""
	docker buildx bake --load \
		--set "*.platform=$(uname -p)" \
		php$${VERSION//.}-$(VARIANT)-all
	PHP_VERSION="$(VERSION)" BRANCH=v5 VARIANT=$(VARIANT) NODE=$(NODE) ./tests-suite/bash_unit -f tap ./tests-suite/*.sh || (notify-send -u critical "Tests failed ($(VERSION)-$(VARIANT)-node$(NODE))" && exit 1)
	notify-send -u critical "Tests passed with success ($(VERSION)-$(VARIANT)-node$(NODE))"

_test-version: _test-prerequisites ## Test php build for VERSION="" and VARIANT=""
	docker buildx bake --load \
		--set "*.platform=$(uname -p)" \
		php$${VERSION//.}-$(VARIANT)-all
	PHP_VERSION="$(VERSION)" BRANCH=v5 VARIANT=$(VARIANT) ./tests-suite/bash_unit -f tap ./tests-suite/*.sh || (notify-send -u critical "Tests failed ($(VERSION)-$(VARIANT))" && exit 1)
	notify-send -u critical "Tests passed with success ($(VERSION)-$(VARIANT))"

_test-version-quick: _test-prerequisites ## Test php build for VERSION="" and VARIANT="" (without node variants)
	docker buildx bake --load \
		--set "*.platform=$(uname -p)" \
		php$${VERSION//.}-slim-$(VARIANT) php$${VERSION//.}-$(VARIANT)
	PHP_VERSION="$(VERSION)" BRANCH=v5 VARIANT=$(VARIANT) ./tests-suite/bash_unit -f tap ./tests-suite/*.sh || (notify-send -u critical "Tests failed ($(VERSION)-$(VARIANT))" && exit 1)
	notify-send -u critical "Tests passed with success ($(VERSION)-$(VARIANT)) - without node-*"

clean: ## Clean dangles image after build
	rm -rf /tmp/buildx-cache


cves:
	docker build \
		--build-arg PHP_VERSION="8.4" \
		--build-arg VARIANT="apache" \
		--build-arg GLOBAL_VERSION="v5" \
		--file ./Dockerfile.slim.apache \
		--tag testv5-slim \
		.
	docker --debug build \
		--build-arg PHP_VERSION="8.4" \
		--build-arg VARIANT="apache" \
		--build-arg GLOBAL_VERSION="v5" \
		--build-arg FROM_IMAGE="testv5-slim" \
		--file ./Dockerfile.apache \
		--tag testv5 \
		.
	docker --debug build \
		--build-arg PHP_VERSION="8.4" \
		--build-arg VARIANT="apache-node22" \
		--build-arg NODE_VERSION="22" \
		--build-arg GLOBAL_VERSION="v5" \
		--build-arg FROM_IMAGE="testv5" \
		--file ./Dockerfile.apache.node \
		--tag testv5-node \
		.
	docker scout cves testv5-node --only-fixed --locations
