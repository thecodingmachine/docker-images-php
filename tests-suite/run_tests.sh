#!/usr/bin/env bash
# Runs the test files for each variant of VARIANTS (and each NodeJS version of NODE_VERSIONS for variant-node.sh),
# TEST_JOBS test files at the same time, with one log per test file in LOG_DIR.
# Usage: VARIANTS="apache cli fpm" NODE_VERSIONS="22 24 26" [TEST_JOBS=2] ./tests-suite/run_tests.sh
set -u
cd "$(dirname "$0")"

export TEST_JOBS="${TEST_JOBS:-2}"
export LOG_DIR="${LOG_DIR:-$(mktemp -d)}"
mkdir -p "${LOG_DIR}"
# Started first so that the longest test files are spread over the parallel jobs instead of ending on a single one
SLOW_TEST_FILES="tool-supercronic.sh onbuild.sh variant-fpm.sh tool-daemon.sh php-extensions.sh"

test_units() {
  local file variant node
  for file in ${SLOW_TEST_FILES} $(ls *.sh | grep -vxF -f <(tr ' ' '\n' <<< "${SLOW_TEST_FILES} run_tests.sh")); do
    for variant in ${VARIANTS}; do
      if [[ "${file}" == "variant-node.sh" ]]; then
        for node in ${NODE_VERSIONS:-}; do echo "${variant} ${file} ${node}"; done
      else
        echo "${variant} ${file}"
      fi
    done
  done
}

run_test_unit() {
  local variant=$1 file=$2 node=${3:-} name start status
  name="${variant}${node:+-node${node}}-${file%.sh}"
  start=${SECONDS}
  if (export VARIANT="${variant}"; if [[ -n "${node}" ]]; then export NODE="${node}"; fi; ./bash_unit -f tap "${file}") > "${LOG_DIR}/${name}.log" 2>&1; then
    status=ok
  else
    status=FAILED
  fi
  echo "${status} ${name} $((SECONDS - start))s"
}
export -f run_test_unit

test_units | xargs -P "${TEST_JOBS}" -L 1 bash -c 'run_test_unit "$@"' _ | tee "${LOG_DIR}/summary"

FAILED=0
for log in "${LOG_DIR}"/*.log; do
  name=$(basename "${log}" .log)
  if grep -q "^FAILED ${name} " "${LOG_DIR}/summary"; then
    FAILED=1
    echo "::group::FAILED ${name}"
  else
    echo "::group::${name}"
  fi
  cat "${log}"
  echo "::endgroup::"
done
if [[ "${FAILED}" == "1" ]]; then
  echo "Failed test files:"
  grep "^FAILED" "${LOG_DIR}/summary"
fi
exit "${FAILED}"
