#!/usr/bin/env bash
# One pass of the watch of the PHP packages of sury: rebuilds each PHP version whose published images do not have the
# packages published by sury (label com.thecodingmachine.php.package of each arch), with workflow.yml (8.2 to 8.5) and
# legacy-v5.yml (NodeJS 18 and 20, PHP 7.4 to 8.1). At most 3 builds for the same packages, successful or not.
#
# Environment:
#   GITHUB_REPOSITORY, GITHUB_REPOSITORY_OWNER, GITHUB_REF_NAME, GH_TOKEN  set by GitHub Actions
#   PHP_VERSIONS  PHP versions to watch (default: all)
#   FIXED         versions fixing a security release, e.g. "8.4=8.4.28 8.1=8.1.34-13": the table says fixed or vulnerable
#   ISSUE         issue with the table of the images in its description, and a digest comment every 30 minutes
#                 at most when the table changes
#   SURY_URL      sury repository (default: https://packages.sury.org/php)
#   DRY_RUN=1     prints the builds instead of launching them
# Exit code: 0 when all the images have the packages of sury (and are fixed when FIXED is set), 3 otherwise.
set -euo pipefail

SURY_URL="${SURY_URL:-https://packages.sury.org/php}"
PHP_VERSIONS="${PHP_VERSIONS:-8.5 8.4 8.3 8.2 8.1 8.0 7.4}"
IMAGE="ghcr.io/${GITHUB_REPOSITORY_OWNER}/php"
LABEL="com.thecodingmachine.php.package"
MAX_BUILDS=3
DIGEST_INTERVAL=1800

[[ "${ISSUE:-}" =~ ^[0-9]*$ ]] || { echo "::error::ISSUE: an issue number"; exit 1; }
[[ "${SURY_URL}" =~ ^https:// ]] || { echo "::error::SURY_URL: https only"; exit 1; }
for V in ${PHP_VERSIONS}; do
  [[ " 8.5 8.4 8.3 8.2 8.1 8.0 7.4 " == *" ${V} "* ]] || { echo "::error::Unknown PHP version: ${V}"; exit 1; }
done
for F in ${FIXED:-}; do
  [[ "${F}" =~ ^[0-9]\.[0-9]=[0-9A-Za-z.:+~-]+$ ]] || { echo "::error::FIXED: X.Y=version, e.g. 8.4=8.4.28"; exit 1; }
done

TMP=$(mktemp -d)
trap 'rm -rf "${TMP}"' EXIT

declare -A FIXED_VERSION=()
for F in ${FIXED:-}; do FIXED_VERSION["${F%%=*}"]="${F#*=}"; done

for ARCH in amd64 arm64; do
  curl -fsS --retry 3 "${SURY_URL}/dists/noble/main/binary-${ARCH}/Packages.gz" | gunzip \
    | awk '$1 == "Package:" {p = $2} $1 == "Version:" && p ~ /^php[0-9.]+-cli$/ {sub(/^php/, "", p); sub(/-cli$/, "", p); print p, $2}' \
    > "${TMP}/sury-${ARCH}"
  [ -s "${TMP}/sury-${ARCH}" ] || { echo "::error::No PHP package in the sury index of ${ARCH}"; exit 1; }
done
sury() { awk -v v="$1" '$1 == v {print $2}' "${TMP}/sury-$2" | sort -V | tail -n 1; }

# Package versions of the published image, one line per arch ("-" without label)
published() {
  docker buildx imagetools inspect "${IMAGE}:$1" --format '{{json .Image}}' 2>/dev/null \
    | jq -r --arg l "${LABEL}" '.["linux/amd64"].config.Labels[$l] // "-", .["linux/arm64"].config.Labels[$l] // "-"' \
    || printf -- '-\n-\n'
}

# Runs of a workflow: "title<TAB>status<TAB>conclusion"
for WF in workflow.yml legacy-v5.yml; do
  gh run list --repo "${GITHUB_REPOSITORY}" --workflow "${WF}" --event workflow_dispatch --limit 100 \
    --json displayTitle,status,conclusion --jq '.[] | [.displayTitle, .status, .conclusion] | @tsv' > "${TMP}/runs-${WF}"
done

upstream() { sed -E 's/^[0-9]+://; s/-[^-]*$//' <<< "$1"; }
is_fixed() {
  local V=$1 P=$2
  [ "${P}" != "-" ] || return 1
  if [ -n "${FIXED_VERSION[$V]:-}" ]; then dpkg --compare-versions "${P}" ge "${FIXED_VERSION[$V]}"
  else [ "${P}" = "$(sury "$V" "$3")" ]; fi
}
cell() {
  local V=$1 P=$2 ARCH=$3
  if [ "${P}" = "-" ]; then echo "❔ unknown"
  elif is_fixed "$V" "$P" "$ARCH"; then echo "✅ $(upstream "$P")"
  elif [ -n "${FIXED_VERSION[$V]:-}" ]; then echo "❌ $(upstream "$P")"
  else echo "⬆️ $(upstream "$P")"; fi
}

# Checks one group of images, launches its build when needed, prints its row of the table
check() {
  local V=$1 WF=$2 TAG=$3 TAGS=$4
  local SURY_AMD SURY_ARM PUB_AMD PUB_ARM STATE TITLE
  SURY_AMD=$(sury "$V" amd64) SURY_ARM=$(sury "$V" arm64)
  { read -r PUB_AMD; read -r PUB_ARM; } < <(published "${TAG}")
  # Same title as the run-name of the workflows
  TITLE="Rebuild PHP ${V} (amd64 ${SURY_AMD}, arm64 ${SURY_ARM})"
  if [ "${PUB_AMD}" = "${SURY_AMD}" ] && [ "${PUB_ARM}" = "${SURY_ARM}" ]; then
    STATE="up to date"
  elif awk -F'\t' -v t="${TITLE}" '$1 == t && $2 != "completed" {f = 1} END {exit !f}' "${TMP}/runs-${WF}"; then
    STATE="🔄 rebuilding"
  elif [ "$(awk -F'\t' -v t="${TITLE}" '$1 == t' "${TMP}/runs-${WF}" | wc -l)" -ge "${MAX_BUILDS}" ]; then
    STATE="⚠️ built ${MAX_BUILDS} times, not published"
    echo "::error::${WF} PHP ${V}: ${MAX_BUILDS} builds for ${TITLE}, the images do not have these packages" >&2
  else
    STATE="🔄 rebuilding"
    echo "${WF}: ${TITLE}" >&2
    if [ "${DRY_RUN:-0}" != 1 ]; then
      gh workflow run "${WF}" --repo "${GITHUB_REPOSITORY}" --ref "${GITHUB_REF_NAME}" \
        -f php_version="${V}" -f package_amd64="${SURY_AMD}" -f package_arm64="${SURY_ARM}" >&2
    fi
  fi
  if [ "${STATE}" = "up to date" ]; then
    if { is_fixed "$V" "${PUB_AMD}" amd64 && is_fixed "$V" "${PUB_ARM}" arm64; }; then STATE="✅ yes"
    elif [ -n "${FIXED_VERSION[$V]:-}" ]; then STATE="waiting for the fixed packages of sury"
    fi
  fi
  echo "| ${V} | ${TAGS} | $(cell "$V" "${PUB_AMD}" amd64) | $(cell "$V" "${PUB_ARM}" arm64) | ${STATE} |"
}

{
  echo "| PHP | Tags | amd64 (x86 servers, PCs) | arm64 (Apple Silicon, Graviton) | Fixed |"
  echo "|---|---|---|---|---|"
  for V in ${PHP_VERSIONS}; do
    if [[ " 7.4 8.0 8.1 " == *" ${V} "* ]]; then
      check "$V" legacy-v5.yml "${V}-v5-slim-cli" "\`${V}-v5-*\`"
    else
      MAIN=$(check "$V" workflow.yml "${V}-v5-slim-cli" "\`${V}-v5-*\` except node18 and node20")
      LEGACY=$(check "$V" legacy-v5.yml "${V}-v5-cli-node20" "\`${V}-v5-*-node18\`, \`${V}-v5-*-node20\`")
      # Same state for both groups of tags: one row
      if [ "$(cut -d'|' -f4- <<< "${MAIN}")" = "$(cut -d'|' -f4- <<< "${LEGACY}")" ]; then
        awk -F'|' -v OFS='|' -v t=" \`${V}-v5-*\` " '{$3 = t; print}' <<< "${MAIN}"
      else
        echo "${MAIN}"; echo "${LEGACY}"
      fi
    fi
  done
} > "${TMP}/table"
grep -qE '🔄|⚠️|waiting|❌|⬆️|❔' "${TMP}/table" && DONE=0 || DONE=1
[ -n "${FIXED:-}" ] || sed -i '1s/| Fixed |/| Up to date |/' "${TMP}/table"
cat "${TMP}/table"

if [ -n "${ISSUE:-}" ] && [ "${DRY_RUN:-0}" != 1 ]; then
  NOW=$(date -u +%s)
  BODY=$(gh issue view "${ISSUE}" --repo "${GITHUB_REPOSITORY}" --json body --jq .body)
  STATE=$(grep -oP '<!-- php-watch:state \K[A-Za-z0-9+/=]+' <<< "${BODY}" | base64 -d 2>/dev/null || echo '{}')
  LAST_KEY=$(jq -r '.key // ""' <<< "${STATE}")
  LAST_DIGEST=$(jq -r '.digest_at // 0' <<< "${STATE}")
  TABLE=$(cat "${TMP}/table")
  # The start of a build is not notified
  KEY=$(sed 's/🔄 rebuilding//' <<< "${TABLE}")

  # Digest: a new comment notifies the subscribers, the previous digests are hidden
  if [ "${KEY}" != "${LAST_KEY}" ] && { [ $((NOW - LAST_DIGEST)) -ge "${DIGEST_INTERVAL}" ] || [ "${DONE}" = 1 ]; }; then
    CHANGED=$({ diff <(echo "${LAST_KEY}") <(echo "${KEY}") || true; } | awk -F'|' '/^> \| [0-9]/ {gsub(/ /, "", $2); print $2}' | sort -uVr | paste -sd, - | sed 's/,/, /g')
    for ID in $(gh api "repos/${GITHUB_REPOSITORY}/issues/${ISSUE}/comments" --paginate \
        --jq '.[] | select(.user.login == "github-actions[bot]" and (.body | contains("<!-- php-watch:digest -->"))) | .node_id'); do
      gh api graphql -f query='mutation($id: ID!) { minimizeComment(input: {subjectId: $id, classifier: OUTDATED}) { clientMutationId } }' \
        -f id="${ID}" > /dev/null
    done
    {
      echo "<!-- php-watch:digest -->"
      if [ "${DONE}" = 1 ]; then echo "**$(date -u '+%Y-%m-%d %H:%M') UTC: all the images are up to date**"
      elif [ -z "${LAST_KEY}" ]; then echo "**$(date -u '+%Y-%m-%d %H:%M') UTC: start of the watch**"
      else echo "**$(date -u '+%Y-%m-%d %H:%M') UTC: PHP ${CHANGED:-?} changed**"; fi
      echo
      echo "${TABLE}"
    } > "${TMP}/digest"
    gh issue comment "${ISSUE}" --repo "${GITHUB_REPOSITORY}" --body-file "${TMP}/digest" > /dev/null
    LAST_KEY="${KEY}" LAST_DIGEST="${NOW}"
  fi

  # Table in the description of the issue, updated at each pass (no notification)
  NEW_STATE=$(jq -cn  --arg k "${LAST_KEY}" --argjson d "${LAST_DIGEST}" '{key: $k, digest_at: $d}' | base64 -w0)
  {
    echo "<!-- php-watch:start -->"
    echo "### Status of the images"
    echo
    echo "${TABLE}"
    echo
    echo "Checked on $(date -u '+%Y-%m-%d %H:%M') UTC. A comment is posted when it changes, every 30 minutes at most."
    echo "<!-- php-watch:state ${NEW_STATE} -->"
    echo "<!-- php-watch:end -->"
  } > "${TMP}/section"
  if grep -q '<!-- php-watch:start -->' <<< "${BODY}"; then
    awk -v f="${TMP}/section" '/<!-- php-watch:start -->/ {while ((getline l < f) > 0) print l; skip = 1} !skip {print} /<!-- php-watch:end -->/ {skip = 0}' \
      <<< "${BODY}" > "${TMP}/body"
  else
    { echo "${BODY}"; echo; cat "${TMP}/section"; } > "${TMP}/body"
  fi
  gh issue edit "${ISSUE}" --repo "${GITHUB_REPOSITORY}" --body-file "${TMP}/body" > /dev/null
fi

[ "${DONE}" = 1 ] || exit 3
