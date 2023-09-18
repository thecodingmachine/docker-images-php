#!/command/with-contenv bash
debug() {
  # TODO : echo report depend of S6_VERBOSITY
  if [[ "${S6_VERBOSITY}" -ge "1" ]]; then
    echo "${1}"
  fi
}
init() {
  SCRIPT_PATH=$( readlink -f -- "$0"; )
  SCRIPT_NAME=$( basename "${SCRIPT_PATH}"; )
  SCRIPT_DIR=$(dirname -- "${SCRIPT_PATH}")
  RC_DIR="/etc/s6-overlay/s6-rc.d/"
  debug "{${SCRIPT_NAME}} START"
}
isLocked() {
  if [[ -e "${SCRIPT_PATH}.lock" ]]; then
    debug "{${SCRIPT_NAME}} Locked (already executed)"
    exit 0
  fi
}
lock() {
  touch "${SCRIPT_PATH}.lock"
}
end() {
  debug "{${SCRIPT_NAME}} END"
}