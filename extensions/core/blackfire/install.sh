#!/usr/bin/env bash

set -e
set -ex

# Install Blackfire
version=$(php -r "echo PHP_MAJOR_VERSION.PHP_MINOR_VERSION;")

if [[ -z "${BLACKFIRE_VERSION}" ]]; then
  echo "Blackfire version is not set in the environment variables. Exiting!"
  exit 1
fi

# Let's make it flexible: for those who want to be safe, the image will be built with v1
# Now if you build the image yourself, you can build it with v2, this way everyone gets happy :)

mkdir /tmp/blackfire

if [ $BLACKFIRE_VERSION == "1" ]; then
    echo "Installing Blackfire version 1"
    # curl -A "Docker" -o /tmp/blackfire-probe.tar.gz -D - -L -s https://blackfire.io/api/v2/releases/probe/php/linux/amd64/$version
    curl -o /tmp/blackfire/blackfire.so "https://packages.blackfire.io/binaries/blackfire-php/1.78.0/blackfire-php-${TARGETOS}"_"${TARGETARCH}-php-${version}.so"
    mv /tmp/blackfire/blackfire.so $(php -r "echo ini_get('extension_dir');")/blackfire.so
    echo "extension=blackfire" > /etc/php/${PHP_VERSION}/mods-available/blackfire.ini

    # Adding this in the list of Ubuntu extensions because we use that list as a base for the modules list.
    # TODO: question: cannot we use /etc/php/mods-available instead???
    touch /var/lib/php/modules/${PHP_VERSION}/registry/blackfire
    # curl -A "Docker" -L https://blackfire.io/api/v1/releases/client/linux_static/amd64 | tar zxp -C /tmp/blackfire
    curl -o /tmp/blackfire/blackfire "https://packages.blackfire.io/binaries/blackfire-agent/1.50.0/blackfire-cli-${TARGETOS}"_"${TARGETARCH}"
    chmod +x /tmp/blackfire/blackfire
    mv /tmp/blackfire/blackfire /usr/bin/blackfire
    rm -Rf /tmp/blackfire

elif [ $BLACKFIRE_VERSION == "2" ]; then
    echo "Installing Blackfire version 2..."
   
    curl -o /tmp/blackfire/blackfire.so "https://packages.blackfire.io/binaries/blackfire-php/1.78.0/blackfire-php-${TARGETOS}"_"${TARGETARCH}-php-${version}.so"
    mv /tmp/blackfire/blackfire.so $(php -r "echo ini_get('extension_dir');")/blackfire.so
    echo "extension=blackfire.so" > /etc/php/${PHP_VERSION}/mods-available/blackfire.ini
    touch /var/lib/php/modules/${PHP_VERSION}/registry/blackfire
    curl -o /tmp/blackfire-cli.tar.gz "https://packages.blackfire.io/binaries/blackfire/2.10.0/blackfire-"${TARGETOS}"_"${TARGETARCH}".tar.gz"
    tar zxpf /tmp/blackfire-cli.tar.gz -C /tmp/blackfire
    mv /tmp/blackfire/blackfire /usr/bin/blackfire

    rm -Rf /tmp/blackfire
else
    echo "Blackfire version in environment variable is either empty or the value is invalid"
    echo "Value: '$BLACKFIRE_VERSION'"
    exit 1
fi