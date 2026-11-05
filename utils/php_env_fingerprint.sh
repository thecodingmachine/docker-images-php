# Fingerprint of the PHP_* environment variables the PHP configuration is generated from
php_env_fingerprint() {
    local name
    for name in "${!PHP_@}"; do
        printf '%s=%s\0' "$name" "${!name}"
    done | md5sum
}
