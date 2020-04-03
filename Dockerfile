FROM circleci/php:7.3-fpm

USER root

# system packages and base php exts
RUN apt-get update && apt-get dist-upgrade && \
    apt-get install zlib1g-dev libsqlite3-dev build-essential libssl-dev libxml2-dev protobuf-compiler nginx && \
    docker-php-ext-install zip pdo_mysql dom fileinfo hash iconv json simplexml tokenizer && \
    rm -rf /usr/local/etc/php-fpm.d/* && \
    ln -sf /dev/stdout /var/log/nginx/access.log && \
    ln -sf /dev/stderr /var/log/nginx/error.log && \
    chown -R circleci /var/log/nginx
# php crypto ext
RUN pecl install crypto-0.3.1 && \
    docker-php-ext-enable crypto
# php curve25519 ext
RUN git clone https://github.com/mgp25/curve25519-php.git && \
    cd curve25519-php && \
    phpize && \
    ./configure && \
    make && \
    make install && \
    docker-php-ext-enable curve25519 && \
    cd ..; rm -rf curve25519-php
# php protobuf ext
RUN git clone https://github.com/allegro/php-protobuf.git && \
    cd php-protobuf && \
    phpize && \
    ./configure && \
    make && \
    make install && \
    docker-php-ext-enable protobuf && \
    cd ..; rm -rf php-protobuf
# php mongodb driver ext
RUN git clone https://github.com/mongodb/mongo-php-driver.git && \
    cd mongo-php-driver && \
    git submodule update --init && \
    phpize && \
    ./configure && \
    make && \
    make install && \
    docker-php-ext-enable mongodb && \
    cd ..; rm -rf mongo-php-driver

# nginx and php-fpm configs
COPY starter.sh /bin/starter
COPY config/php/php-fpm.d /usr/local/etc/php-fpm.d
COPY config/nginx /etc/nginx
RUN chmod +x /bin/starter

USER circleci
