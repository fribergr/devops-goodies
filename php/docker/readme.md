# Production ready docker container for PHP (Laravel)
Most of the time you can get by with just using something like `php:8.5-apache-trixie` as your base and reconfiguring the ports to work in OpenShift. However, sometimes you need some extra performance and your application might not be runnable inside something like Swoole, RoadRunner or FrankenPHP.

The setup is split in two layers:

* **A runtime image** (`runtime-image/`), built in its own repository. It is `php:8.5-fpm-alpine` plus nginx and the PHP extensions most applications share. Every pipeline pushes an immutable tag (`php:8.5-<pipeline iid>`) and a floating one (`php:8.5`). Renovate (`docker:pinDigests`) opens a merge request whenever the upstream image changes, and merging it rebuilds the image, so security fixes reach it without anyone keeping track.
* **The application image** (`Dockerfile`), built from the application repository on top of a pinned runtime image tag. Since the heavy lifting already happened in the runtime image, these builds are fast. The application's own Renovate config (`renovate.json`) bumps the pinned tag when a new runtime image is published.

Copy the contents of this folder (except `runtime-image/`) into your application and point the final `FROM` at your runtime image.

## Migrations
The image contains `/migrate`, which runs `php artisan migrate`. On Kubernetes, run it as an init container (see [kubernetes](../../kubernetes/demo-app/deployment.yaml)), never as part of the deploy or the container's entrypoint. A heavy migration can take longer than the probes allow, and a container killed halfway through a migration is not something you want to clean up.
