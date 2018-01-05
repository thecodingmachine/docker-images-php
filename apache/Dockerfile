FROM php:7.1.12-apache

MAINTAINER Julien Neuhart <j.neuhart@thecodingmachine.com>

# |--------------------------------------------------------------------------
# | Main PHP extensions
# |--------------------------------------------------------------------------
# |
# | Installs the main PHP extensions
# |

RUN apt-get update &&\
    apt-get install -y --no-install-recommends \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libmcrypt-dev \
    libpng12-dev \
    zlib1g-dev \
    libicu-dev \
    libxml2-dev \
    libyaml-dev \
    g++

RUN set -xe &&\
    docker-php-ext-configure bcmath --enable-bcmath &&\
    docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ &&\
    docker-php-ext-configure intl --enable-intl &&\
    docker-php-ext-configure mbstring --enable-mbstring &&\
    docker-php-ext-configure mcrypt --enable-mcrypt &&\
    docker-php-ext-configure pdo_mysql --with-pdo-mysql &&\
    docker-php-ext-configure opcache --enable-opcache &&\
    docker-php-ext-configure soap --enable-soap &&\
    docker-php-ext-configure zip --enable-zip &&\
    docker-php-ext-install \
        bcmath \
        gd \
        intl \
        mbstring \
        mcrypt \
        pdo_mysql \
        opcache \
        soap \
        zip

# |--------------------------------------------------------------------------
# | APCu extension
# |--------------------------------------------------------------------------
# |
# | Installs the APCu extension for PHP.
# |

ENV APCU_VERSION 5.1.9

RUN mkdir -p /usr/src/php/ext/apcu &&\
    curl -L https://github.com/krakjoe/apcu/archive/v$APCU_VERSION.tar.gz | tar xvz -C /usr/src/php/ext/apcu --strip 1 &&\
    echo 'apcu' >> /usr/src/php-available-exts &&\
    docker-php-ext-install apcu

# |--------------------------------------------------------------------------
# | PHP extension for Redis
# |--------------------------------------------------------------------------
# |
# | Installs the Redis extension for PHP.
# |

ENV PHPREDIS_VERSION 3.1.6

RUN mkdir -p /usr/src/php/ext/redis &&\
    curl -L https://github.com/phpredis/phpredis/archive/$PHPREDIS_VERSION.tar.gz | tar xvz -C /usr/src/php/ext/redis --strip 1 &&\
    echo 'redis' >> /usr/src/php-available-exts &&\
    docker-php-ext-install redis

# |--------------------------------------------------------------------------
# | YAML extension
# |--------------------------------------------------------------------------
# |
# | Installs the YAML extension for PHP.
# |

ENV YAML_VERSION 2.0.2

RUN mkdir -p /usr/src/php/ext/yaml &&\
    curl -L https://github.com/php/pecl-file_formats-yaml/archive/$YAML_VERSION.tar.gz | tar xvz -C /usr/src/php/ext/yaml --strip 1 &&\
    echo 'yaml' >> /usr/src/php-available-exts &&\
    docker-php-ext-install yaml

# |--------------------------------------------------------------------------
# | Xdebug
# |--------------------------------------------------------------------------
# |
# | Installs Xdebug, a tool for easily debugging your PHP code.
# |

ENV XDEBUG_VERSION XDEBUG_2_5_5

RUN mkdir -p /usr/src/php/ext/xdebug &&\
    curl -L https://github.com/xdebug/xdebug/archive/$XDEBUG_VERSION.tar.gz | tar xvz -C /usr/src/php/ext/xdebug --strip 1 &&\
    echo 'xdebug' >> /usr/src/php-available-exts &&\
    docker-php-ext-install xdebug &&\
    { \
        echo 'xdebug.remote_enable=on'; \
        echo 'xdebug.remote_autostart=off'; \
        echo 'xdebug.remote_port=9000'; \
        echo 'xdebug.remote_handler=dbgp'; \
        echo 'xdebug.remote_connect_back=0'; \
    } >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini

# |--------------------------------------------------------------------------
# | Git
# |--------------------------------------------------------------------------
# |
# | Installs Git command (useful for Composer).
# |

RUN apt-get install -y --no-install-recommends git

# |--------------------------------------------------------------------------
# | Composer
# |--------------------------------------------------------------------------
# |
# | Installs Composer to easily manage your PHP dependencies.
# |
ENV COMPOSER_VERSION 1.6.2
ENV COMPOSER_ALLOW_SUPERUSER 1

RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer --version=$COMPOSER_VERSION &&\
    chmod +x /usr/local/bin/composer

# |--------------------------------------------------------------------------
# | prestissimo
# |--------------------------------------------------------------------------
# |
# | Installs prestissimo to fix Composer performance issues.
# |

ENV PRESTISSIMO_VERSION 0.3.7

RUN composer global require hirak/prestissimo:$PRESTISSIMO_VERSION --verbose

# |--------------------------------------------------------------------------
# | PHP Coding Standards Fixer
# |--------------------------------------------------------------------------
# |
# | The PHP Coding Standards Fixer tool fixes most issues in your code when
# | you want to follow the PHP coding standards as defined in the PSR-1 and
# | PSR-2 documents and many more.
# |

ENV PHP_CS_FIXER_VERSION 2.9.0

RUN apt-get update &&\
    apt-get install -y --no-install-recommends wget &&\
    wget https://github.com/FriendsOfPHP/PHP-CS-Fixer/releases/download/v$PHP_CS_FIXER_VERSION/php-cs-fixer.phar -O php-cs-fixer &&\
    chmod a+x php-cs-fixer &&\
    mv php-cs-fixer /usr/local/bin/php-cs-fixer

# |--------------------------------------------------------------------------
# | NodeJS
# |--------------------------------------------------------------------------
# |
# | Installs NodeJS and npm. The later will allow you to easily manage
# | your frontend dependencies.
# |

ENV NODE_VERSION 8.9.4

RUN curl -sL https://deb.nodesource.com/setup_8.x | bash - &&\
    apt-get update &&\
    apt-get install -y --no-install-recommends nodejs

# |--------------------------------------------------------------------------
# | yarn
# |--------------------------------------------------------------------------
# |
# | Installs yarn. It provides some nice improvements over npm.
# |

ENV YARN_VERSION 1.3.2

RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - &&\
    echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list &&\
    apt-get update &&\
    apt-get install -y --no-install-recommends yarn

# |--------------------------------------------------------------------------
# | Apache mod_rewrite
# |--------------------------------------------------------------------------
# |
# | Enables Apache mod_rewrite.
# |

RUN a2enmod rewrite

# |--------------------------------------------------------------------------
# | Entrypoint
# |--------------------------------------------------------------------------
# |
# | Defines the entrypoint.
# |

COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]

CMD ["/usr/sbin/apachectl", "-DFOREGROUND"]