{% if image.variant == "fpm" -%}
###################################################
## FPM With Apache #TODO another with apache-php-mod ?
## https://wiki.alpinelinux.org/wiki/Apache_with_php-fpm
###################################################
ENV APACHE_DOCUMENT_ROOT=""
ENV APACHE_MAX_CONNECTIONS_PER_CHILD=0
ENV APACHE_MAX_REQUEST_WORKERS=150
ENV APACHE_MAX_SPARE_THREADS=75
ENV APACHE_MIN_SPARE_THREADS=10
ENV APACHE_START_SERVERS=2
ENV APACHE_THREAD_LIMIT=64
ENV APACHE_THREADS_PER_CHILD=25
#RUN if [[ "${FROM_VARIANT}" != "-fpm" ]]; then exit 0; fi; \
#    apk --no-cache apache2-proxy && \
#    cat <<EOF >> /etc/apache2/httpd.conf
#<FilesMatch \.php$>
#    SetHandler "proxy:fcgi://127.0.0.1:9000"
#</FilesMatch>
#EOF
EXPOSE 80
EXPOSE 443
EXPOSE 443/udp
{%- endif %}