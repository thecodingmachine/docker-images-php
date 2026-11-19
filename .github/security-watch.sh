#!/usr/bin/env bash
# Watches the PHP packages of sury and starts the builds of the PHP versions whose packages changed.
# The state is kept in the comments of the security issue: each one ends with a line
#   <!-- security-watch {"php": "8.4", "amd64": "<package>", "arm64": "<package>", "event": "...", ...} -->
# - dispatched: written here when the builds of a pair of packages are started
# - published / failed: written by the builds (workflow.yml: "main", legacy-v5.yml: "legacy")
# - maintained-complete / complete / deadline: written here once
#
# Environment: GH_TOKEN, REPOSITORY, ISSUE, REF, BASELINE (JSON {"8.4": {"amd64": "<package>", "arm64": "<package>"}}),
# DEADLINE (ISO 8601), DRY_RUN=1 to only print what would be done.
set -euo pipefail

MAINTAINED="8.5 8.4 8.3 8.2"
LEGACY="8.1 8.0 7.4"
ARCHS="amd64 arm64"
MAX_DISPATCHES=3
ACTIONS_URL="https://github.com/${REPOSITORY}/actions"

comment() {
  local TEXT="$1" STATE="$2"
  if [ "${DRY_RUN:-0}" == "1" ]; then
    echo "[dry-run] comment: ${TEXT} ${STATE}"
    return
  fi
  gh issue comment "${ISSUE}" --repo "${REPOSITORY}" --body "${TEXT}"$'\n\n'"<!-- security-watch ${STATE} -->"
}

dispatch() {
  local WORKFLOW="$1" PHP="$2" AMD64="$3" ARM64="$4"
  if [ "${DRY_RUN:-0}" == "1" ]; then
    echo "[dry-run] dispatch ${WORKFLOW} ${PHP} ${AMD64} ${ARM64}"
    return
  fi
  gh workflow run "${WORKFLOW}" --repo "${REPOSITORY}" --ref "${REF}" \
    -f php_version="${PHP}" -f package_amd64="${AMD64}" -f package_arm64="${ARM64}" -f security_issue="${ISSUE}"
}

stop_watching() {
  if [ "${DRY_RUN:-0}" != "1" ]; then
    gh workflow disable security-watch.yml --repo "${REPOSITORY}"
  fi
}

# PHP version of a package version: 1:8.4.28-1+0~deb.sury.org.1+ubuntu24.04 -> 8.4.28
upstream() {
  sed -E 's/^[0-9]+://; s/-[^-]*$//' <<< "$1"
}

declare -A PACKAGE
for ARCH in ${ARCHS}; do
  while read -r NAME VERSION; do
    PACKAGE["${NAME}/${ARCH}"]="${VERSION}"
  done < <(curl -fsS --retry 3 "https://packages.sury.org/php/dists/noble/main/binary-${ARCH}/Packages.gz" | gunzip \
    | awk '/^Package: php[0-9.]+-cli$/ {p = $2} /^Version:/ {if (p) {print p, $2; p = ""}}')
done

STATES=$(gh api --paginate "repos/${REPOSITORY}/issues/${ISSUE}/comments" --jq '.[] | select(.user.login == "github-actions[bot]") | .body' \
  | sed -nE 's/^<!-- security-watch (\{.*\}) -->$/\1/p' | jq -sc '.')

has_event() {
  jq -e --arg event "$1" 'any(.[]; .event == $event)' <<< "${STATES}" > /dev/null
}

SUMMARY="| PHP | amd64 | arm64 | Images |"$'\n'"|---|---|---|---|"
ALL_DONE=1
MAINTAINED_DONE=1
for PHP in ${MAINTAINED} ${LEGACY}; do
  AMD64="${PACKAGE[php${PHP}-cli/amd64]:-}"
  ARM64="${PACKAGE[php${PHP}-cli/arm64]:-}"
  FIXED_ARCHS=0
  declare -A LABEL=()
  for ARCH in ${ARCHS}; do
    CURRENT="${PACKAGE[php${PHP}-cli/${ARCH}]:-}"
    BASE=$(jq -r --arg php "${PHP}" --arg arch "${ARCH}" '.[$php][$arch] // ""' <<< "${BASELINE}")
    if [ -n "${CURRENT}" ] && dpkg --compare-versions "${CURRENT}" gt "${BASE}"; then
      FIXED_ARCHS=$((FIXED_ARCHS + 1))
      LABEL[${ARCH}]="✅ $(upstream "${CURRENT}")"
    else
      LABEL[${ARCH}]="⏳ not published yet"
    fi
  done

  if [[ " ${MAINTAINED} " == *" ${PHP} "* ]]; then
    WORKFLOWS="main legacy"
  else
    WORKFLOWS="legacy"
  fi
  TARGET=$(jq -c --arg php "${PHP}" --arg amd64 "${AMD64}" --arg arm64 "${ARM64}" \
    '[.[] | select(.php == $php and .amd64 == $amd64 and .arm64 == $arm64)]' <<< "${STATES}")
  DISPATCHES=$(jq '[.[] | select(.event == "dispatched")] | length' <<< "${TARGET}")
  FAILURES=$(jq '[.[] | select(.event == "failed")] | length' <<< "${TARGET}")
  PUBLISHED=1
  for WORKFLOW in ${WORKFLOWS}; do
    jq -e --arg wf "${WORKFLOW}" 'any(.[]; .event == "published" and .workflow == $wf)' <<< "${TARGET}" > /dev/null || PUBLISHED=0
  done

  if [ "${FIXED_ARCHS}" == "0" ]; then
    IMAGES="waiting for sury"
  elif [ "${PUBLISHED}" == "1" ]; then
    IMAGES="published"
  elif [ "${DISPATCHES}" == "0" ] || { [ "${FAILURES}" -ge "${DISPATCHES}" ] && [ "${DISPATCHES}" -lt "${MAX_DISPATCHES}" ]; }; then
    IMAGES="build started"
    for WORKFLOW in ${WORKFLOWS}; do
      case "${WORKFLOW}" in
        main) dispatch workflow.yml "${PHP}" "${AMD64}" "${ARM64}" ;;
        legacy) dispatch legacy-v5.yml "${PHP}" "${AMD64}" "${ARM64}" ;;
      esac
    done
    RETRY=""
    if [ "${DISPATCHES}" -gt 0 ]; then
      RETRY=" (retry ${DISPATCHES}/$((MAX_DISPATCHES - 1)))"
    fi
    STATE=$(jq -nc --arg php "${PHP}" --arg amd64 "${AMD64}" --arg arm64 "${ARM64}" \
      '{php: $php, amd64: $amd64, arm64: $arm64, event: "dispatched"}')
    comment "🔨 PHP ${PHP}: sury packages amd64 ${LABEL[amd64]}, arm64 ${LABEL[arm64]}. Build started${RETRY}. [Actions](${ACTIONS_URL})" "${STATE}"
  elif [ "${FAILURES}" -ge "${DISPATCHES}" ]; then
    IMAGES="❌ build failed ${FAILURES} times, needs a maintainer"
  else
    IMAGES="build in progress"
  fi
  SUMMARY+=$'\n'"| ${PHP} | ${LABEL[amd64]} | ${LABEL[arm64]} | ${IMAGES} |"

  if [ "${FIXED_ARCHS}" != "2" ] || [ "${PUBLISHED}" != "1" ]; then
    ALL_DONE=0
    if [[ " ${MAINTAINED} " == *" ${PHP} "* ]]; then
      MAINTAINED_DONE=0
    fi
  fi
  unset LABEL
done

echo "${SUMMARY}"
if [ -n "${GITHUB_STEP_SUMMARY:-}" ]; then
  echo "${SUMMARY}" >> "${GITHUB_STEP_SUMMARY}"
fi

if [ "${ALL_DONE}" == "1" ]; then
  has_event complete || comment "🎉 All the v5 images are fixed, on amd64 and arm64. The watch stops."$'\n\n'"${SUMMARY}" '{"event": "complete"}'
  stop_watching
  exit 0
fi
if [ "${MAINTAINED_DONE}" == "1" ] && ! has_event maintained-complete; then
  comment "🎉 PHP 8.2 to 8.5 are fixed, on amd64 and arm64. The watch goes on for PHP 7.4, 8.0 and 8.1."$'\n\n'"${SUMMARY}" '{"event": "maintained-complete"}'
fi
if [ "$(date -u +%s)" -ge "$(date -u -d "${DEADLINE}" +%s)" ]; then
  has_event deadline || comment "⏰ End of the automatic watch: what is not fixed yet is followed by hand."$'\n\n'"${SUMMARY}" '{"event": "deadline"}'
  stop_watching
fi
