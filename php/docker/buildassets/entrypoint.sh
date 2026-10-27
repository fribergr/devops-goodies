#!/bin/sh
set -e

/usr/local/bin/php /var/www/artisan optimize
# nginx runs in the background and php-fpm in the foreground, so the container
# exits if php-fpm dies. If nginx dies, port 8080 closes and the liveness probe
# restarts the pod.
/usr/sbin/nginx &
PHP_INI_SCAN_DIR=/usr/local/etc/php/conf.d:/etc/php-fpm/conf.d exec /usr/local/sbin/php-fpm -R -F
