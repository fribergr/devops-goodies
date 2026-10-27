# GitLab Runner by HTTP
Monitors a gitlab-runner through its built-in Prometheus metrics endpoint. No exporter needed, and since the runner usually runs on a VM or a machine of its own, no proxy either.

It keeps track of version changes and restarts, job slot usage, jobs started, finished and failed (split by job errors and runner errors), job run and queue time, GitLab API errors and errors in the runner log. Every `[[runners]]` section in the runner's config is discovered automatically.

## Configuring the runner
Enable the metrics endpoint in the global section of `config.toml` and restart gitlab-runner:
```toml
listen_address = ":9252"
```
If the runner runs in Docker, publish the port as well (`-p 9252:9252`).

## Configuring Zabbix
1. Import `zbx_gitlab_runner_by_http.yaml`.
2. Create one host per gitlab-runner process (one metrics endpoint) and link *GitLab Runner by HTTP*.
3. Set `{$GITLAB_RUNNER.METRICS.URL}`, e.g. `http://runner.local:9252/metrics`.

To skip some runners, set `{$GITLAB_RUNNER.LLD.FILTER.NAME.NOT_MATCHES}`. Queue time, failed jobs and API errors thresholds support macro context, so they can be set per runner, e.g. `{$GITLAB_RUNNER.QUEUE.TIME.MAX:"my-runner"}`.
