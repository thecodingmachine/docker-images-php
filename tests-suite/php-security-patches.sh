#!/usr/bin/env bash
. ./config

############################################################
## php2shell: CVE-2026-109618 and CVE-2026-109619
############################################################
# Fixed upstream in 8.2.35, 8.3.36, 8.4.27 and 8.5.12.
# The end-of-life branches (7.4, 8.0, 8.1) only got a source backport that keeps the
# version number (7.4.33, 8.0.30, 8.1.34): it is detected with the zend_mm_safe_error_ex
# symbol it adds to the Zend engine, in every PHP SAPI shipped in the image.
# The fixed packages are not yet published for arm64: a vulnerable arm64 image is only a warning.
test_php2shellPatched() {
  IMAGE="${REPO}:${TAG_PREFIX}${PHP_VERSION}-${BRANCH}-${BRANCH_VARIANT}${ARCH_SUFFIX}"
  if [[ "$(printf '%s\n' "$PHP_VERSION" "8.2" | sort -V | head -n 1)" != "8.2" ]]; then
    RESULT="$(docker run ${RUN_OPTIONS} --rm "${IMAGE}" \
      bash -c 'dpkg --print-architecture
               for BIN in /usr/bin/php${PHP_VERSION} /usr/sbin/php-fpm${PHP_VERSION} /usr/lib/apache2/modules/libphp${PHP_VERSION}.so; do
                 [ -e "${BIN}" ] || continue
                 grep -q zend_mm_safe_error_ex "${BIN}" && echo "patched ${BIN}" || echo "vulnerable ${BIN}"
               done' 2>/dev/null)"
    if [[ "$RESULT" == arm64* ]] && [[ "$RESULT" == *vulnerable* ]]; then
      echo "::warning::${IMAGE} (arm64) is vulnerable to CVE-2026-109618: PHP SAPI without the backport"
      return
    fi
    assert_matches "patched /usr/bin/php${PHP_VERSION}" "$RESULT" "PHP CLI not found or not patched"
    assert_not_matches "vulnerable" "$RESULT" "PHP SAPI without the CVE-2026-109618 backport"
  else
    case "${PHP_VERSION}" in
      8.2) FIXED_VERSION="8.2.35" ;;
      8.3) FIXED_VERSION="8.3.36" ;;
      8.4) FIXED_VERSION="8.4.27" ;;
      *) FIXED_VERSION="8.5.12" ;;
    esac
    RESULT="$(docker run ${RUN_OPTIONS} --rm "${IMAGE}" \
      bash -c 'dpkg --print-architecture; php -r "echo PHP_VERSION;"' 2>/dev/null)"
    ARCH="$(head -n 1 <<< "$RESULT")"
    VERSION="$(tail -n 1 <<< "$RESULT")"
    if [[ "$ARCH" == "arm64" ]] && [[ "$(printf '%s\n' "$VERSION" "${FIXED_VERSION}" | sort -V | head -n 1)" != "${FIXED_VERSION}" ]]; then
      echo "::warning::${IMAGE} (arm64): PHP ${VERSION} is vulnerable to CVE-2026-109618 (fixed in ${FIXED_VERSION})"
      return
    fi
    assert_equals "${FIXED_VERSION}" "$(printf '%s\n' "$VERSION" "${FIXED_VERSION}" | sort -V | head -n 1)" \
      "PHP ${VERSION} is vulnerable to CVE-2026-109618 (fixed in ${FIXED_VERSION})"
  fi
}
