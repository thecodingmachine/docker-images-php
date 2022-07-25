SHELL=/bin/bash

blueprint: ## Generate all blueprints file
	@if ! type orbit >/dev/null 2>&1; then echo "Missing orbit dependency, please install from https://github.com/gulien/orbit/"; exit 1; fi
	orbit run generate

test-latest: test-8.1 ## Test the latest build only

_test-prerequisites: blueprint
	docker pull ubuntu:20.04

test-quick:  ## Test 8.0 and 8.1 quickly
	VERSION=8.0 VARIANT=cli $(MAKE) _test-version
	VERSION=8.1 VARIANT=cli $(MAKE) _test-version

test-8.1:  ## Test php8.1 build only
	VERSION=8.1 VARIANT=cli $(MAKE) _test-version
	VERSION=8.1 VARIANT=apache $(MAKE) _test-version

test-8.0:  ## Test php8.0 build only
	VERSION=8.0 VARIANT=cli $(MAKE) _test-version
	VERSION=8.0 VARIANT=apache $(MAKE) _test-version

_test-version: _test-prerequisites ## Test php build for VERSION="" and VARIANT=""
	docker buildx bake --load \
	    --set "*.platform=$$(uname -p)" \
		php$${VERSION//.}-cli
	PHP_VERSION="$(VERSION)" BRANCH=v4 VARIANT=cli ./test-image.sh || (notify-send -u critical "Tests failed ($(VERSION)-$(VARIANT))" && exit 1)
	notify-send -u critical "Tests passed with success ($(VERSION)-$(VARIANT))"

clean: ## Clean dangles image after build
	rm -rf /tmp/buildx-cache