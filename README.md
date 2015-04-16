# docker-mariadb

## MariaDB Galera Cluster

Initialize a new cluster:

```bash
docker run -i -t --rm \
-e MYSQL_ROOT_PASSWORD=test \
-e XTRABACKUP_PASSWORD=test \
-e CLUSTER_NAME=test \
-e CLUSTER_ADDRESS=gcomm:// \
hauptmedia/10.0-galera-xtrabackup --wsrep-new-cluster
```

Join a node to the cluster:

```bash
docker run -i -t --rm \
-e MYSQL_ROOT_PASSWORD=test \
-e XTRABACKUP_PASSWORD=test \
-e CLUSTER_NAME=test \
-e CLUSTER_ADDRESS=gcomm://ip1,ip2 \
hauptmedia/10.0-galera-xtrabackup
```
