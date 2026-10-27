# Zabbix
I use Zabbix for monitoring. Since moving a lot of my stuff to Kubernetes, most metrics are exposed in the Prometheus format instead of through a Zabbix agent. The templates in this folder read those endpoints with Zabbix HTTP agent items, so there is no Prometheus server and no Zabbix agent involved.

Each folder holds a template (`zbx_*.yaml`) and, where needed, the Kubernetes configuration for its exporter:

* [proxy](proxy/) - a Zabbix proxy inside the cluster, which the other templates poll through
* [mysql](mysql/readme.md) - MySQL through mysqld_exporter
* [redis](redis/readme.md) - Redis through a shared redis_exporter
* [gitlab-runner](gitlab-runner/readme.md) - GitLab Runner through its built-in metrics endpoint

The templates are exported from Zabbix 7.4. Import them under *Data collection → Templates → Import*.

## Zabbix proxy
The exporters only listen inside the cluster, so the polling is done by a Zabbix proxy running in it. `proxy/zabbix-proxy.k8s.yaml` runs an active proxy, meaning it connects out to the Zabbix server and nothing has to be exposed. Set `ZBX_HOSTNAME` and `ZBX_SERVER_HOST`, then add a proxy with the same name under *Administration → Proxies* (mode: Active).

Every host using the MySQL or Redis template must be set to *Monitored by proxy* with this proxy, otherwise the server tries to resolve `*.svc.cluster.local` itself and gets no data.
