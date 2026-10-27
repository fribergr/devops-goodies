# Redis by redis_exporter
Monitors Redis through [redis_exporter](https://github.com/oliver006/redis_exporter). Instead of one exporter per Redis, a single exporter per cluster runs in multi-target mode and scrapes whichever Redis it is asked for (`/scrape?target=redis://…`). Adding another Redis is then just another Zabbix host.

It keeps track of whether Redis is up and restarts, memory usage against `maxmemory` (or the pod's limit), evictions and refused writes, `maxmemory-policy`, connected and rejected clients, command rate, background saves and the number of keys per database.

## Deploying the exporter
Apply `redis-exporter.k8s.yaml` in the namespace where the Zabbix proxy runs. The exporter needs the password of every Redis it scrapes. These are stored in a JSON file mapping each target to its password, kept as a SealedSecret (see the comments at the top of the file).

The file is only read at startup, so after adding a Redis and resealing, restart the exporter pod.

## Configuring Zabbix
1. Import `zbx_redis_by_redis_exporter.yaml`.
2. Create a host for each Redis (or use the host of the application it belongs to), set it to be monitored by the cluster's proxy and link *Redis by redis_exporter*.
3. Set `{$REDIS.TARGET}` to `redis://redis.<namespace>.svc.cluster.local:6379`. It must be exactly the same string as the key in the password file.
4. If the Redis has no `maxmemory` set, set `{$REDIS.MEM.LIMIT}` to the pod's memory limit in bytes. Otherwise the memory triggers never fire.

`{$REDIS.EXPORTER.URL}` defaults to `http://redis-exporter.zabbix.svc.cluster.local:9121` and only needs changing if the exporter lives elsewhere.
