FROM php:8.5.12-fpm-alpine

ENV TZ=Europe/Stockholm

COPY --from=mlocati/php-extension-installer:2.12.3 /usr/bin/install-php-extensions /usr/local/bin/

RUN apk add --no-cache \
        nginx=1.30.6-r0 \
        tzdata \
    && install-php-extensions \
        apcu \
        bcmath \
        curl \
        intl \
        mbstring \
        pcntl \
        pdo_mysql \
        redis \
        zip \
    && php -r 'foreach (["apcu", "bcmath", "curl", "intl", "mbstring", "pcntl", "pdo_mysql", "redis", "zip"] as $extension) { if (!extension_loaded($extension)) { fwrite(STDERR, "Missing PHP extension: $extension" . PHP_EOL); exit(1); } }'

ADD https://raw.githubusercontent.com/vishnubob/wait-for-it/81b1373f17855a4dc21156cfe1694c31d7d1792e/wait-for-it.sh /usr/local/bin/wait-for-it
RUN chmod +x /usr/local/bin/wait-for-it
