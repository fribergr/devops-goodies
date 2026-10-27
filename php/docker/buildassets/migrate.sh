#!/bin/sh
set -e

# Run as an init container, never from the app container or a deploy script:
# probes can kill the app container in the middle of a long migration.
# --isolated takes a cache lock, so pods starting together migrate only once
# (needs a cache store with locks, such as redis or database).
/usr/local/bin/php /var/www/artisan migrate --force --isolated
