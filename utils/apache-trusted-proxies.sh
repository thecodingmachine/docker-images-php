#!/bin/bash
# Usage: apache-trusted-proxies.sh generate|watch|enabled
#
# Writes the mod_remoteip configuration of the proxies of APACHE_TRUSTED_PROXIES (host names resolved by the container,
# IPs and CIDR ranges) and, with APACHE_TRUSTED_CLOUDFLARE=1, of the ranges published by Cloudflare.
# APACHE_TRUSTED_CLOUDFLARE=only also refuses (403) the requests that did not go through Cloudflare: the ones of the
# proxies without a Cloudflare hop, or every one but localhost without proxies.
# The client IP is the first address of X-Forwarded-For, from the right, that is not a trusted proxy.
# Behind Cloudflare, CF-Connecting-IP is added to the left of X-Forwarded-For: it is only reached when the hop added
# before it is a Cloudflare address, even if a proxy in between replaced X-Forwarded-For.
# A request from a trusted proxy with "X-Forwarded-Proto: https" gets HTTPS=on.
#
# enabled: succeeds when a proxy or Cloudflare is trusted
# watch: resolves the names every 30 seconds and downloads the Cloudflare ranges every day, then reloads Apache
# gracefully when the configuration changed.

CONF=/etc/apache2/conf-enabled/docker-trusted-proxies.conf
CLOUDFLARE_BUNDLED=/etc/apache2/cloudflare-ips.txt
CLOUDFLARE_DOWNLOADED=/var/lib/apache2/cloudflare-ips.txt
CLOUDFLARE_URLS=(https://www.cloudflare.com/ips-v4 https://www.cloudflare.com/ips-v6)
read -ra ENTRIES <<< "${APACHE_TRUSTED_PROXIES//,/ }"

log() {
    echo "[APACHE_TRUSTED_PROXIES] $*" >&2
}

case "${APACHE_TRUSTED_CLOUDFLARE,,}" in
    1|true|yes|on) WITH_CLOUDFLARE=1 CLOUDFLARE_ONLY=0 ;;
    only) WITH_CLOUDFLARE=1 CLOUDFLARE_ONLY=1 ;;
    ''|0|false|no|off) WITH_CLOUDFLARE=0 CLOUDFLARE_ONLY=0 ;;
    *) log "Invalid APACHE_TRUSTED_CLOUDFLARE value: \"$APACHE_TRUSTED_CLOUDFLARE\". Valid values are \"only\", \"0\", \"1\", \"yes\", \"no\", \"true\", \"false\", \"on\", \"off\"."
       exit 1 ;;
esac

is_address() {
    [[ "$1" =~ ^[0-9]{1,3}(\.[0-9]{1,3}){3}(/[0-9]{1,2})?$ ]] || [[ "$1" =~ ^[0-9a-fA-F:]*:[0-9a-fA-F:.]*(/[0-9]{1,3})?$ ]]
}

# Prints the valid ranges of a list, fails if one line is not a range or if there are less than 10 of them
valid_ranges() {
    local ranges
    ranges=$(tr -d '\r' < "$1" | grep -v '^[[:space:]]*$') || return 1
    while read -r RANGE; do
        is_address "$RANGE" || return 1
    done <<< "$ranges"
    (( $(wc -l <<< "$ranges") >= 10 )) || return 1
    echo "$ranges"
}

cloudflare_ranges() {
    valid_ranges "$CLOUDFLARE_DOWNLOADED" 2> /dev/null || cat "$CLOUDFLARE_BUNDLED"
}

download_cloudflare_ranges() {
    local tmp
    tmp=$(mktemp)
    for URL in "${CLOUDFLARE_URLS[@]}"; do
        if ! curl -fsS --max-time 10 "$URL" >> "$tmp" 2> /dev/null; then
            rm -f "$tmp"
            return 1
        fi
        echo >> "$tmp"
    done
    if ! valid_ranges "$tmp" > "$CLOUDFLARE_DOWNLOADED.tmp"; then
        rm -f "$tmp" "$CLOUDFLARE_DOWNLOADED.tmp"
        return 1
    fi
    rm -f "$tmp"
    mv "$CLOUDFLARE_DOWNLOADED.tmp" "$CLOUDFLARE_DOWNLOADED"
}

ipmatch() {
    local first=1
    for RANGE in "$@"; do
        (( first )) || printf ' || '
        printf "%%{CONN_REMOTE_ADDR} -ipmatch '%s'" "$RANGE"
        first=0
    done
}

UNRESOLVED_WARNING=
# Returns 1 when the configuration is unchanged
generate() {
    local proxies=() cloudflare=() unresolved=() addresses conf
    (( WITH_CLOUDFLARE )) && mapfile -t cloudflare < <(cloudflare_ranges)
    for ENTRY in "${ENTRIES[@]}"; do
        if is_address "$ENTRY"; then
            proxies+=("$ENTRY")
        else
            addresses=$(getent ahosts "$ENTRY" | awk '{ print $1 }' | sort -u)
            if [[ -z "$addresses" ]]; then
                unresolved+=("$ENTRY")
            else
                mapfile -t -O "${#proxies[@]}" proxies <<< "$addresses"
            fi
        fi
    done

    if [[ "$1" == "watch" ]] && [[ "${unresolved[*]}" != "$UNRESOLVED_WARNING" ]]; then
        if (( ${#unresolved[@]} > 0 )); then
            log "Cannot resolve ${unresolved[*]}: their requests keep the IP of the proxy until they are resolved"
        else
            log "All the proxies are resolved"
        fi
        UNRESOLVED_WARNING="${unresolved[*]}"
    fi

    conf="# Generated from APACHE_TRUSTED_PROXIES=$APACHE_TRUSTED_PROXIES APACHE_TRUSTED_CLOUDFLARE=$APACHE_TRUSTED_CLOUDFLARE"$'\n'
    if (( ${#proxies[@]} + ${#cloudflare[@]} > 0 )); then
        conf+="RemoteIPHeader X-Forwarded-For"$'\n'
        (( ${#proxies[@]} )) && conf+="RemoteIPInternalProxy ${proxies[*]}"$'\n'
        (( ${#cloudflare[@]} )) && conf+="RemoteIPTrustedProxy ${cloudflare[*]}"$'\n'
        if (( ${#cloudflare[@]} )); then
            conf+='RequestHeader set X-Forwarded-For "expr=%{HTTP:CF-Connecting-IP}, %{HTTP:X-Forwarded-For}" early'$'\n'
            conf+='RequestHeader edit X-Forwarded-For "^[^,]*, $" "" early'$'\n'
            conf+='RequestHeader edit X-Forwarded-For "^, " "" early'$'\n'
        fi
        conf+="<If \"%{HTTP:X-Forwarded-Proto} == 'https' && ($(ipmatch "${proxies[@]}" "${cloudflare[@]}"))\">"$'\n'
        conf+="    SetEnv HTTPS on"$'\n'
        conf+="</If>"$'\n'
    fi
    if (( CLOUDFLARE_ONLY )); then
        # Only the Cloudflare ranges (RemoteIPTrustedProxy) are listed in RemoteIPProxiesHeader
        conf+='RequestHeader unset X-Cloudflare-Hop early'$'\n'
        conf+='RemoteIPProxiesHeader X-Cloudflare-Hop'$'\n'
        if (( ${#proxies[@]} )); then
            conf+="<If \"-z %{HTTP:X-Cloudflare-Hop} && ($(ipmatch "${proxies[@]}"))\">"$'\n'
        else
            conf+="<If \"-z %{HTTP:X-Cloudflare-Hop} && ! ($(ipmatch 127.0.0.0/8 ::1))\">"$'\n'
        fi
        conf+="    Require all denied"$'\n'
        conf+="</If>"$'\n'
        conf+='RequestHeader unset X-Cloudflare-Hop'$'\n'
    fi

    if [[ -f "$CONF" ]] && [[ "$(cat "$CONF")"$'\n' == "$conf" ]]; then
        return 1
    fi
    printf '%s' "$conf" > "$CONF"
}

reload_apache() {
    : "${APACHE_PID_FILE:=/var/run/apache2/apache2.pid}"
    local pid
    pid=$(cat "$APACHE_PID_FILE" 2> /dev/null)
    if [[ -z "$pid" ]] || [[ "$(cat "/proc/$pid/comm" 2> /dev/null)" != "apache2" ]]; then
        return
    fi
    if ! apache2ctl configtest > /dev/null 2>&1; then
        log "Invalid Apache configuration, Apache is not reloaded:"
        apache2ctl configtest >&2
        return
    fi
    kill -USR1 "$pid"
}

watch() {
    local now downloaded=0 attempted=0
    trap 'exit 0' TERM INT
    while true; do
        now=$(date +%s)
        if (( WITH_CLOUDFLARE && now - downloaded >= 86400 && now - attempted >= 3600 )); then
            attempted=$now
            if download_cloudflare_ranges; then
                downloaded=$now
            else
                log "Cannot download the Cloudflare ranges, the previous ones are kept (next try in 1 hour)"
            fi
        fi
        if generate watch; then
            log "Proxies updated, reloading Apache"
            reload_apache
        fi
        sleep 30 &
        wait $!
    done
}

case "$1" in
    generate) generate; exit 0 ;;
    enabled) [[ -n "$APACHE_TRUSTED_PROXIES" ]] || (( WITH_CLOUDFLARE )) ;;
    watch) watch ;;
    *) echo "Usage: $0 generate|watch|enabled" >&2; exit 2 ;;
esac
