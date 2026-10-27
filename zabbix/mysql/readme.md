# MySQL by mysqld_exporter
Monitors a MySQL server through [mysqld_exporter](https://github.com/prometheus/mysqld_exporter), running as a sidecar in the MySQL pod.

It keeps track of whether MySQL is up and restarts, connection usage and refused connections, query rates and slow queries, InnoDB buffer pool hit ratio, table cache misses and the size of each database.

## Deploying the exporter
`mysqld-exporter.k8s.yaml` contains the sidecar container, the MySQL user it needs and the `.my.cnf` secret (comments at the top), plus a Service with the metrics port added next to MySQL's own.

Without `--collect.info_schema.tables` everything works except database discovery, which stays empty.

## Configuring Zabbix
1. Import `zbx_mysql_by_mysqld_exporter.yaml`.
2. Create a host for the MySQL server, set it to be monitored by the cluster's proxy and link *MySQL by mysqld_exporter*.
3. Set `{$MYSQL.EXPORTER.SVC}` to `<service>.<namespace>.svc.cluster.local:9104`. The default, `mysql.mysql.svc.cluster.local:9104`, matches the example Service.

The trigger thresholds are macros as well (`{$MYSQL.CONN.UTIL.WARN}`, `{$MYSQL.SLOW_QUERIES.MAX}` etc.) and can be overridden per host. Which databases are discovered is controlled by `{$MYSQL.SCHEMA.MATCHES}` and `{$MYSQL.SCHEMA.NOT_MATCHES}`.
