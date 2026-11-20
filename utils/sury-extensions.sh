#!/usr/bin/env bash
# Compares the extensions of a PHP version (extensions/<version>) with those of a reference version and with the
# packages published by sury for noble, on amd64 and arm64. Prints a Markdown table, with the symlink to add or remove.
# Exit code 1 when an extension of extensions/<version> has no package on an arch (the build of the version fails).
# Usage: utils/sury-extensions.sh <version> [<reference version, the previous one by default>]
set -euo pipefail
cd "$(dirname "$0")/.."

VERSION="$1"
REFERENCE="${2:-$(ls -d extensions/[0-9]* | xargs -n 1 basename | sort -V | grep -B 1 -x "${VERSION}" | head -n 1)}"
ARCHS="amd64 arm64"

# php<VERSION>-* names of an arch: "<name> package" for a package, "<name> <package>" when another package provides it
declare -A AVAILABLE
for ARCH in ${ARCHS}; do
  while read -r NAME SOURCE; do
    [[ "${SOURCE}" == package || -z "${AVAILABLE[${ARCH}/${NAME}]:-}" ]] && AVAILABLE["${ARCH}/${NAME}"]="${SOURCE}"
  done < <(curl -fsS --retry 3 "https://packages.sury.org/php/dists/noble/main/binary-${ARCH}/Packages.gz" | gunzip \
    | awk -v prefix="php${VERSION}-" '
        $1 == "Package:" { package = $2; if (index(package, prefix) == 1) print package, "package" }
        $1 == "Provides:" && index(package, prefix) == 1 {
          sub(/^Provides: */, ""); n = split($0, provided, /, */)
          for (i = 1; i <= n; i++) { split(provided[i], name, " "); if (index(name[1], prefix) == 1) print name[1], package }
        }')
done

# Package of an extension, read from its install.sh: PACKAGE_NAME, or else EXTENSION (empty for PECL or another source)
package_of() {
  local dir install
  for dir in "extensions/${VERSION}/$1" "extensions/${REFERENCE}/$1" "extensions/core/$1"; do
    [[ -f "${dir}/install.sh" ]] && install="${dir}/install.sh" && break
  done
  [[ -n "${install:-}" ]] || return 0
  grep -oP '(^|\s)PACKAGE_NAME=\K[a-z0-9_]+' "${install}" | head -n 1 && return 0
  grep -oP '(^|\s)EXTENSION=\K[a-z0-9_]+' "${install}" | head -n 1 || true
}

status_of() {
  local name="php${VERSION}-$1" source="${AVAILABLE[$2/php${VERSION}-$1]:-}"
  case "${source}" in
    package) echo "${name}" ;;
    "") echo "missing" ;;
    *) echo "in ${source}" ;;
  esac
}

MISSING_LINKED=0
echo "| Extension | ${REFERENCE} | ${VERSION} | sury amd64 | sury arm64 | To do |"
echo "|---|---|---|---|---|---|"
for EXT in $( (ls "extensions/${REFERENCE}"; ls "extensions/${VERSION}" 2>/dev/null) | grep -v '\.sh$' | sort -u); do
  IN_REFERENCE=$([[ -e "extensions/${REFERENCE}/${EXT}" ]] && echo yes || echo no)
  LINKED=$([[ -e "extensions/${VERSION}/${EXT}" ]] && echo yes || echo no)
  PACKAGE=$(package_of "${EXT}")
  if [[ -z "${PACKAGE}" ]]; then
    echo "| ${EXT} | ${IN_REFERENCE} | ${LINKED} | not from sury | not from sury | |"
    continue
  fi
  AMD64=$(status_of "${PACKAGE}" amd64)
  ARM64=$(status_of "${PACKAGE}" arm64)
  TODO=""
  if [[ "${AMD64}" != missing && "${ARM64}" != missing && "${LINKED}" == no ]]; then
    TODO="add the symlink"
  elif [[ ( "${AMD64}" == missing || "${ARM64}" == missing ) && "${LINKED}" == yes ]]; then
    TODO="**build fails**"
    MISSING_LINKED=1
  fi
  echo "| ${EXT} | ${IN_REFERENCE} | ${LINKED} | ${AMD64} | ${ARM64} | ${TODO} |"
done
exit "${MISSING_LINKED}"
