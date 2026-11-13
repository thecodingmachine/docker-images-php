#!/bin/bash
# Called by rotatelogs with the new log file ($1): gzips the previous files of the same log, and deletes the ones older
# than APACHE_LOG_RETENTION_DAYS days.

NAME="$(basename "$1")"
PREFIX="$(dirname "$1")/${NAME%%.*}"
for FILE in "$PREFIX".*.log; do
    [[ -f "$FILE" ]] && [[ "$FILE" != "$1" ]] && gzip -f "$FILE"
done
find "$(dirname "$1")" -maxdepth 1 -name "${NAME%%.*}.*.log.gz" -mtime +"${APACHE_LOG_RETENTION_DAYS:-14}" -delete
