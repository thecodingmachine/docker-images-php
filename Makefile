SHELL=/bin/bash

blueprint: ## Generate all blueprints file
	@if ! type orbit >/dev/null 2>&1; then echo "Missing orbit dependency, please install from https://github.com/gulien/orbit/"; exit 1; fi
	orbit run generate

test-latest: test-8.2 ## Test the latest build only

_test-prerequisites: blueprint
	docker pull ubuntu:22.04

test-quick:  ## Test 8.0, 8.1 and 8.2 quickly
	VERSION=8.0 VARIANT=cli $(MAKE) _test-version-quick
	VERSION=8.1 VARIANT=cli $(MAKE) _test-version-quick
	VERSION=8.2 VARIANT=cli $(MAKE) _test-version-quick

test-8.2:  ## Test php8.2 build only
	VERSION=8.2 VARIANT=cli $(MAKE) _test-version
	VERSION=8.2 VARIANT=apache $(MAKE) _test-version
	VERSION=8.2 VARIANT=fpm $(MAKE) _test-version

test-8.1:  ## Test php8.1 build only
	VERSION=8.1 VARIANT=cli $(MAKE) _test-version
	VERSION=8.1 VARIANT=apache $(MAKE) _test-version
	VERSION=8.1 VARIANT=fpm $(MAKE) _test-version

test-8.0:  ## Test php8.0 build only
	VERSION=8.0 VARIANT=cli $(MAKE) _test-version
	VERSION=8.0 VARIANT=apache $(MAKE) _test-version
	VERSION=8.0 VARIANT=fpm $(MAKE) _test-version

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