FROM circleci/php:7.3-fpm

USER root

ENV NVM_DIR "/opt/nvm"

# dist upgrade
RUN apt-get update && apt-get dist-upgrade
# node.js deps
COPY nvm-install.sh /root/nvm-install.sh
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 5DC22404A6F9F1CA && \
    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 78BD65473CB3BD13 && \
    mkdir -p $NVM_DIR && chmod +x /root/nvm-install.sh && /root/nvm-install.sh && \
    \. $NVM_DIR/nvm.sh && nvm install v10.16.0 && nvm use v10.16.0 && \
    echo ". $NVM_DIR/nvm.sh" >> /home/circleci/.bashrc
# php system deps
RUN apt-get install zlib1g-dev libsqlite3-dev build-essential libssl-dev libxml2-dev protobuf-compiler nginx jq python3-pip && \
    docker-php-ext-install zip pdo_mysql dom fileinfo hash iconv json simplexml tokenizer && \
    pip3 install awscli && \
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

EXPOSE 8000 8080
USER circleci
