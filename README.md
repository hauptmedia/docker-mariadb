# docker-mariadb

## MariaDB Galera Cluster

For known limitations have a look at https://mariadb.com/kb/en/mariadb/mariadb-galera-cluster-known-limitations


### Initializing a new cluster

```bash
docker run -i -t --rm \
-e TIMEZONE=Europe/Berlin \
-e MYSQL_ROOT_PASSWORD=test \
-e REPLICATION_PASSWORD=test \
-e GALERA=On \
-e NODE_NAME=node1 \
-e CLUSTER_NAME=test \
-e CLUSTER_ADDRESS=gcomm://ipOrHost1,ipOrHost2,ipOrHost3 \
hauptmedia/mariadb:10.1 --wsrep-new-cluster
```

### Joining a node to the cluster

```bash
docker run -i -t --rm \
-e TIMEZONE=Europe/Berlin \
-e MYSQL_ROOT_PASSWORD=test \
-e REPLICATION_PASSWORD=test \
-e GALERA=On \
-e NODE_NAME=node2 \
-e CLUSTER_NAME=test \
-e CLUSTER_ADDRESS=gcomm://ipOrHost1,ipOrHost2,ipOrHost3 \
hauptmedia/mariadb:10.1
```

Please note: if you don't specify the timezone the server will run with UTC time

## Recover strategies

To fix a split brain in a failed cluster make sure that only one node remains in the cluster and run

`SET GLOBAL wsrep_provider_options='pc.bootstrap=true';`

For more information about recovering a galera cluster have a look at https://www.percona.com/blog/2014/09/01/galera-replication-how-to-recover-a-pxc-cluster/
