#!/usr/bin/env bash

set -e
set -ex

# Install Blackfire
if [[ -z "${BLACKFIRE_VERSION}" ]]; then
  echo "Blackfire version is not set in the environment variables. Exiting!"
  exit 1
fi

# Let's make it flexible: for those who want to be safe, the image will be built with v1
# Now if you build the image yourself, you can build it with v2, this way everyone gets happy :)

version=$(php -r "echo PHP_MAJOR_VERSION.PHP_MINOR_VERSION;")
# Probe is the same for v1 and v2
curl -A "Docker" -o /tmp/blackfire-probe.tar.gz -D - -L -s https://blackfire.io/api/v1/releases/probe/php/${TARGETOS}/${TARGETARCH}/$version
mkdir -p /tmp/blackfire
tar zxpf /tmp/blackfire-probe.tar.gz -C /tmp/blackfire
mv /tmp/blackfire/blackfire-*.so $(php -r "echo ini_get ('extension_dir');")/blackfire.so
printf "extension=blackfire.so" > "/etc/php/${PHP_VERSION}/mods-available/blackfire.ini"
rm -rf /tmp/blackfire /tmp/blackfire-probe.tar.gz

if [ $BLACKFIRE_VERSION == "1" ]; then
  # Cli for v1 require specific version
  curl -A "Docker" "https://packages.blackfire.io/binaries/blackfire-agent/1.50.0/blackfire-cli-${TARGETOS}"_"${TARGETARCH}"  -o /tmp/blackfire
  chmod +x /tmp/blackfire
  mv /tmp/blackfire /usr/bin/blackfire
  rm -Rf /tmp/blackfire
elif [ $BLACKFIRE_VERSION == "2" ]; then
  # Cli for v2 is latest version
  echo "Installing Blackfire version 2..."
  mkdir -p /tmp/blackfire
  curl -A "Docker" -L https://blackfire.io/api/v1/releases/cli/linux/${TARGETARCH} | tar zxp -C /tmp/blackfire
  if ! /tmp/blackfire/blackfire self:version --no-ansi | grep -qE "version 2\.[0-9]+\.[0-9]+"; then
    echo "Blackfire installed is not version 2 : $(/tmp/blackfire/blackfire self:version --no-ansi)"
    exit 1
  fi
  mv /tmp/blackfire/blackfire /usr/bin/blackfire
  rm -Rf /tmp/blackfire
else
    echo "Blackfire version in environment variable is either empty or the value is invalid"
    echo "Value: '$BLACKFIRE_VERSION'"
    exit 1
fi