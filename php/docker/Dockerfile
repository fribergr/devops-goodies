FROM composer:2.10 AS vendor
WORKDIR /app/
COPY composer.json composer.lock /app/
RUN composer install \
    --ignore-platform-reqs \
    --no-interaction \
    --no-plugins \
    --no-scripts \
    --no-dev \
    --prefer-dist

# Plain Node is enough for laravel-vite-plugin. If your build runs artisan
# (the Wayfinder Vite plugin does), use your PHP build image here instead and
# copy vendor/ in from the stage above before building.
FROM node:24-alpine AS frontend
WORKDIR /app/
COPY package.json package-lock.json /app/
RUN npm ci --no-audit --no-fund --prefer-offline --progress=false
COPY . /app/
RUN npm run build

# Built by the runtime-images repo (see runtime-image/). Pin the per-pipeline
# tag and let Renovate bump it (see renovate.json).
FROM registry.local/runtime-images/php:8.5-1

# Extensions your application needs on top of the runtime image.
# RUN install-php-extensions gd exif

# The production php.ini, with app.ini on top for every SAPI and fpm.ini on
# top of that for FPM only (the entrypoint adds its directory to
# PHP_INI_SCAN_DIR).
RUN cp "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"
COPY buildassets/php/app.ini /usr/local/etc/php/conf.d/99-app.ini
COPY buildassets/php/fpm.ini /etc/php-fpm/conf.d/99-fpm.ini

# Pool config, nginx config and log wiring. The base image's docker.conf
# logs every FPM request to stderr; nginx already logs them, minus probes.
COPY buildassets/www.conf /usr/local/etc/php-fpm.d/www.conf
COPY buildassets/nginx.conf /etc/nginx/nginx.conf
RUN sed -i '/^access.log/d' /usr/local/etc/php-fpm.d/docker.conf && \
    mkdir -p /var/log/nginx /run/nginx /var/cache/php/opcache-cli && \
    ln -sf /dev/stdout /var/log/nginx/access.log && \
    ln -sf /dev/stderr /var/log/nginx/error.log && \
    chmod 1777 /var/cache/php/opcache-cli

COPY buildassets/entrypoint.sh /init
COPY buildassets/migrate.sh /migrate
RUN chmod +x /init /migrate

WORKDIR /var/www
COPY . /var/www
COPY --from=frontend /app/public/ /var/www/public/
COPY --from=vendor /app/vendor/ /var/www/vendor/
COPY --from=vendor /usr/bin/composer /usr/bin/composer
# Composer and package:discover run with the CLI opcache file cache on, which
# would otherwise ship the compiled build-time scripts in this layer.
RUN composer dump-autoload --no-dev --optimize && \
    rm -rf /var/cache/php/opcache-cli/* && \
    chown -R www-data:www-data /var/www/storage /var/www/bootstrap/cache

ENTRYPOINT ["/init"]
