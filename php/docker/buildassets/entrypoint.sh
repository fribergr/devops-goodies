#!/bin/sh
/usr/bin/php /var/www/artisan route:cache
/usr/bin/php /var/www/artisan config:cache
/usr/bin/php /var/www/artisan view:cache
/usr/sbin/php-fpm${PHP_VERSION} -R -D
/usr/sbin/nginx
