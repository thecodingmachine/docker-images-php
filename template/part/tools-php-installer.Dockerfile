###################################################
## PHP Extension installer
## https://github.com/mlocati/docker-php-extension-installer
###################################################
RUN curl -sSLf \
            -o /usr/local/bin/install-php-extensions \
            https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions && \
    chmod +x /usr/local/bin/install-php-extensions
RUN install-php-extensions @composer-${COMPOSER_VERSION}
#RUN install-php-extensions gd