# Fingerprint of the PHP_* environment variables the PHP configuration is generated from
php_env_fingerprint() {
    local name
    for name in "${!PHP_@}"; do
        # PHP_PROFILE triggers the profiling of a command, it does not change the configuration
        [[ "$name" == PHP_PROFILE ]] && continue
        printf '%s=%s\0' "$name" "${!name}"
    done | md5sum
}
