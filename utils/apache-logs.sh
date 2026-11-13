#!/bin/bash
# Writes the log configuration of Apache from APACHE_LOG_FORMAT, APACHE_LOG_OUTPUT, APACHE_LOG_RETENTION_DAYS and
# APACHE_LOG_MAX_SIZE.
#
# APACHE_LOG_FORMAT: combined (default), detailed (combined + response time in µs + address of the proxy), json, or
# a format of mod_log_config.
# APACHE_LOG_OUTPUT: stdout (default: access log on stdout, error log on stderr) or file (files of
# $APACHE_LOG_DIR rotated every day at midnight UTC and when they reach APACHE_LOG_MAX_SIZE, gzipped and deleted after
# APACHE_LOG_RETENTION_DAYS days).

CONF=/etc/apache2/conf-enabled/docker-logs.conf
: "${APACHE_LOG_DIR:=/var/log/apache2}"

log() {
    echo "[APACHE_LOG] $*" >&2
}

case "${APACHE_LOG_FORMAT:-combined}" in
    combined) FORMAT='%h %l %u %t \"%r\" %>s %O \"%{Referer}i\" \"%{User-Agent}i\"' ;;
    detailed) FORMAT='%h %l %u %t \"%r\" %>s %O \"%{Referer}i\" \"%{User-Agent}i\" %D %{c}a' ;;
    json) FORMAT='{\"time\":\"%{%Y-%m-%dT%H:%M:%S%z}t\",\"ip\":\"%a\",\"proxy\":\"%{c}a\",\"method\":\"%m\",\"uri\":\"%U%q\",\"protocol\":\"%H\",\"status\":%>s,\"bytes\":%O,\"duration_us\":%D,\"referer\":\"%{Referer}i\",\"user_agent\":\"%{User-Agent}i\"}' ;;
    *%*) FORMAT="${APACHE_LOG_FORMAT//\"/\\\"}" ;;
    *) log "Invalid APACHE_LOG_FORMAT value: \"$APACHE_LOG_FORMAT\". Valid values are \"combined\", \"detailed\", \"json\" or a format of mod_log_config (with % fields)."
       exit 1 ;;
esac

case "${APACHE_LOG_OUTPUT:-stdout}" in
    stdout)
        ERROR_LOG="\${APACHE_LOG_DIR}/error.log"
        ACCESS_LOG="\${APACHE_LOG_DIR}/access.log"
        ;;
    file)
        if [[ ! "${APACHE_LOG_RETENTION_DAYS:-14}" =~ ^[0-9]+$ ]]; then
            log "Invalid APACHE_LOG_RETENTION_DAYS value: \"$APACHE_LOG_RETENTION_DAYS\" (a number of days)."
            exit 1
        fi
        if [[ -n "$APACHE_LOG_MAX_SIZE" ]] && [[ ! "$APACHE_LOG_MAX_SIZE" =~ ^[0-9]+[KMG]$ ]]; then
            log "Invalid APACHE_LOG_MAX_SIZE value: \"$APACHE_LOG_MAX_SIZE\" (a size like 100M, 500K or 1G)."
            exit 1
        fi
        for LINK in error.log access.log other_vhosts_access.log; do
            [[ -L "$APACHE_LOG_DIR/$LINK" ]] && rm -f "$APACHE_LOG_DIR/$LINK"
        done
        ROTATE="|/usr/bin/rotatelogs -p /usr/local/bin/apache-log-rotated.sh"
        if [[ -n "$APACHE_LOG_MAX_SIZE" ]]; then
            SUFFIX="%Y-%m-%d.%H%M%S.log 86400 $APACHE_LOG_MAX_SIZE"
        else
            SUFFIX="%Y-%m-%d.log 86400"
        fi
        ERROR_LOG="\"$ROTATE \${APACHE_LOG_DIR}/error.$SUFFIX\""
        ACCESS_LOG="\"$ROTATE \${APACHE_LOG_DIR}/access.$SUFFIX\""
        ;;
    *) log "Invalid APACHE_LOG_OUTPUT value: \"$APACHE_LOG_OUTPUT\". Valid values are \"stdout\" and \"file\"."
       exit 1 ;;
esac

cat > "$CONF" <<CONF
# Generated from APACHE_LOG_FORMAT, APACHE_LOG_OUTPUT, APACHE_LOG_RETENTION_DAYS and APACHE_LOG_MAX_SIZE
LogFormat "$FORMAT" docker
ErrorLog $ERROR_LOG
CustomLog $ACCESS_LOG docker
CONF
