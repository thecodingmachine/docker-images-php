#!/usr/bin/env bash
. ./config

############################################################
## The locales listed in LOCALES are available
############################################################
test_generateLocales() {
  RESULT="$(docker run ${RUN_OPTIONS} --rm -e LOCALES="fr_FR.UTF-8 de_DE.UTF-8" \
    "${REPO}:${TAG_PREFIX}${PHP_VERSION}-${BRANCH}-${BRANCH_VARIANT}${ARCH_SUFFIX}" \
    php -r 'echo setlocale(LC_ALL, "fr_FR.UTF-8"), " ", setlocale(LC_ALL, "de_DE.UTF-8");' 2>/dev/null)"
  assert_equals "fr_FR.UTF-8 de_DE.UTF-8" "$RESULT"
}
############################################################
## LOCALES fails with a message in a slim image without INSTALL_LOCALES
############################################################
test_displayErrorWhenMissing() {
  RESULT=$(docker run ${RUN_OPTIONS} --rm -e LOCALES="fr_FR.UTF-8" \
    "${REPO}:${TAG_PREFIX}${PHP_VERSION}-${BRANCH}-slim-${BRANCH_VARIANT}${ARCH_SUFFIX}" sleep 1 2>&1 | tail -n +1 | grep -o 'Locales are not available in this image')
  assert_equals "Locales are not available in this image" "$RESULT"
}
