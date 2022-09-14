FROM ubuntu:focal as builder
ENV DEBIAN_FRONTEND noninteractive
ENV PHP_VERSION 8.1
ENV REDIS_VERSION 5.3.7
RUN apt-get update && apt-get install -y software-properties-common curl inetutils-syslogd && \
    apt-add-repository ppa:nginx/stable -y && \
    LC_ALL=C.UTF-8 apt-add-repository ppa:ondrej/php -y && \
    apt-get update && apt-get install -y \
    php${PHP_VERSION}-dev \
    zip \
    unzip && \
    apt-get autoremove -y && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN curl -L -o /tmp/redis.tar.gz https://github.com/phpredis/phpredis/archive/$REDIS_VERSION.tar.gz \
    && tar xfz /tmp/redis.tar.gz \
    && rm -r /tmp/redis.tar.gz \
    && mkdir -p /usr/src/php/ext \
    && mv phpredis-* /usr/src/php/ext/redis \
    && cd /usr/src/php/ext/redis \
    && phpize \
    && ./configure \
    && make



FROM ubuntu:focal

ADD https://raw.githubusercontent.com/vishnubob/wait-for-it/master/wait-for-it.sh /bin/wait-for-it.sh
RUN chmod 755 /bin/wait-for-it.sh

ENV DEBIAN_FRONTEND noninteractive
ENV PHP_VERSION 8.1

RUN apt-get update && apt-get install -y software-properties-common curl inetutils-syslogd && \
    apt-add-repository ppa:nginx/stable -y && \
    LC_ALL=C.UTF-8 apt-add-repository ppa:ondrej/php -y && \
    apt-get update && apt-get install -y \
    php${PHP_VERSION}-fpm \
    php${PHP_VERSION}-curl \
    php${PHP_VERSION}-cli \
    php${PHP_VERSION}-intl \
    php${PHP_VERSION}-mysql \
    php${PHP_VERSION}-xml \
    php${PHP_VERSION}-bcmath \
    php${PHP_VERSION}-mbstring \
    php-ast \
    php${PHP_VERSION}-zip \
    php${PHP_VERSION}-sqlite3 \
    php${PHP_VERSION}-apcu \
    zip \
    unzip \
    nginx && \
    apt-get autoremove -y && apt-get clean && rm -rf /var/lib/apt/lists/* && \
    mkdir -p /run/php && chmod -R 755 /run/php && \
    sed -i 's|.*listen =.*|listen=/run/php/php-fpm.sock|g' /etc/php/${PHP_VERSION}/fpm/pool.d/www.conf && \
    sed -i 's|.*error_log =.*|error_log=/proc/self/fd/2|g' /etc/php/${PHP_VERSION}/fpm/php-fpm.conf && \
    #sed -i 's/.*log_level = .*/log_level = debug/g' /etc/php/${PHP_VERSION}/fpm/php-fpm.conf && \
    sed -i 's|^user =.*||g' /etc/php/${PHP_VERSION}/fpm/pool.d/www.conf && \
    sed -i 's|^group =.*||g' /etc/php/${PHP_VERSION}/fpm/pool.d/www.conf && \
    sed -i 's|^listen.group =.*||g' /etc/php/${PHP_VERSION}/fpm/pool.d/www.conf && \
    sed -i 's|^listen.owner =.*||g' /etc/php/${PHP_VERSION}/fpm/pool.d/www.conf && \
    sed -i 's|^pm.max_children =.*|pm.max_children = 70|g' /etc/php/${PHP_VERSION}/fpm/pool.d/www.conf && \
    sed -i 's|^pm.start_servers =.*|pm.start_servers = 40|g' /etc/php/${PHP_VERSION}/fpm/pool.d/www.conf && \
    sed -i 's|^pm.min_spare_servers =.*|pm.min_spare_servers = 40|g' /etc/php/${PHP_VERSION}/fpm/pool.d/www.conf && \
    sed -i 's|^pm.max_spare_servers =.*|pm.max_spare_servers = 60|g' /etc/php/${PHP_VERSION}/fpm/pool.d/www.conf && \
    sed -i -e "s/;catch_workers_output\s*=\s*yes/catch_workers_output = yes/g" /etc/php/${PHP_VERSION}/fpm/pool.d/www.conf && \
    sed -i -e "s/;pm\.status_path\s*=\s*\/status/pm\.status_path = \/status/g" /etc/php/${PHP_VERSION}/fpm/pool.d/www.conf && \
    sed -i 's#.*variables_order.*#variables_order=EGPCS#g' /etc/php/${PHP_VERSION}/fpm/php.ini && \
    sed -i 's#.*date.timezone.*#date.timezone=UTC#g' /etc/php/${PHP_VERSION}/fpm/pool.d/www.conf && \
    sed -i 's#.*clear_env.*#clear_env=no#g' /etc/php/${PHP_VERSION}/fpm/pool.d/www.conf


# Copy NGINX service script
COPY buildassets/nginx.conf /etc/nginx/nginx.conf
RUN rm /var/log/nginx/access.log && \
    ln -s /dev/stdout /var/log/nginx/access.log && \
    rm /var/log/nginx/error.log && \
    ln -s /dev/stderr /var/log/nginx/error.log && \
    chmod 777 /var/lib/nginx -R && \
    touch /run/nginx.pid && \
    chmod 666 /run/nginx.pid

RUN mkdir -p /run/php && chmod 777 /run/php -R

COPY buildassets/optimize.ini /etc/php/8.1/fpm/conf.d/

COPY --from=builder /usr/src/php/ext/redis/modules/redis.so /usr/lib/php/20210902/
COPY buildassets/redis.ini /etc/php/8.1/fpm/conf.d/
COPY buildassets/redis.ini /etc/php/8.1/cli/conf.d/
COPY buildassets/entrypoint.sh /init
RUN chmod +x /init

COPY . /var/www
ENTRYPOINT ["/init"]
