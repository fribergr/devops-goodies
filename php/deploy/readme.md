# Deploying a PHP application
If you are using Kubernetes, take a look at [ArgoCD](https://argo-cd.readthedocs.io/en/stable/) and our [kubernetes](../../kubernetes/readme.md) readme.

If you are deploying to static VMs or physical machines, I'd suggest using [Envoy](https://laravel.com/docs/9.x/envoy#main-content) from [Laravel](https://laravel.com/).

## Envoy
Envoy is a cli tool that executes commands on remote servers over ssh.
The way this works is that you create a `Envoy.blade.php`-file in your application git-repo. This file specifies your configuration in PHP and blade-syntax.

An example of this file could look like:

```php
@setup
    $__container->servers([
        'server.local' => 'user@server.local',
    ]);
    $paths = [
        'server.local' => '/var/www/myapp',
    ];
    $phpservices = [
        'server.local' => 'php8.1-fpm',
    ];
    $workers = [
        'server.local' => 'queue-worker:queue-worker_00',
    ];
    $repository = 'ssh://git@git.local/Application/Repository';
    $app_dir = $paths[$server];
    $app_service = $phpservices[$server];
    $worker = $workers[$server];
    $releases_dir = "$app_dir/releases";
    $release = date('YmdHis');
    $new_release_dir = $releases_dir .'/'. $release;
    $branch = $branch ?? "master";
@endsetup

@story('deploy', ['on' => $server])
    clone_repository
    run_composer
    npm_install
    npm_run_prod
    update_symlinks
    run_migration
    update_current_release
    reload_php
@endstory

@task('clone_repository')
    echo 'Cloning repository'
    [ -d {{ $releases_dir }} ] || mkdir {{ $releases_dir }}
    git clone {{ $repository }} {{ $new_release_dir }}
    cd {{ $new_release_dir }}
    echo 'Git reset hard {{ $commit }}'
    git reset --hard {{ $commit }}
@endtask

@task('run_composer')
    echo "Starting deployment ({{ $release }})"
    cd {{ $new_release_dir }}
    COMPOSER_ALLOW_SUPERUSER=1 composer install --prefer-dist --no-scripts -q -o --no-dev
@endtask

@task('npm_install')
    echo "NPM install"
    cd {{ $new_release_dir }}
    npm install --silent --no-progress
@endtask

@task('npm_run_prod')
    echo "NPM run prod"
    cd {{ $new_release_dir }}
    npm run prod --silent --no-progress
    npm run clean
@endtask

@task('update_symlinks')
    echo "Linking storage directory"
    rm -rf {{ $new_release_dir }}/storage
    ln -nfs {{ $app_dir }}/storage {{ $new_release_dir }}/storage

    echo 'Linking .env file'
    ln -nfs {{ $app_dir }}/.env {{ $new_release_dir }}/.env
@endtask

@task('run_migration')
    echo "Running database migrations"
    cd {{ $new_release_dir }}
    php artisan migrate --force
@endtask

@task('update_current_release')
    echo 'Linking current release'
    ln -nfs {{ $new_release_dir }} {{ $app_dir }}/current
@endtask

@task('reload_php')
    echo 'Reloading php-fpm'
    sudo systemctl reload {{ $app_service }}
    echo 'Restarting worker (if needed)'
    [ "x{{ $worker }}" != "x" ] && sudo supervisorctl restart {{ $worker }}
@endtask

```

To get this to work, a few things need to exist before running the actual deployment:
* User running deployment must have a unlocked ssh-key that is added to the `~/.ssh/authorized_keys` on the remote server
* User on the remote server must have a ssh-keypair without a password, where the public key is added to the git repository as a read only deploy key.
* User on the remote server must have added git server to their known_hosts

When the above is setup, you can run a command like:
```bash
~/.composer/vendor/bin/envoy run deploy --server=server.local --commit="$CI_COMMIT_SHA"
```

This includes `$CI_COMMIT_SHA` which is a gitlab-ci predefined variable that points to the specific commit hash you wish to deploy.

