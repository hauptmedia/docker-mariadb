# docker-mariadb

## MariaDB Galera Cluster

Initialize a new cluster:

```bash
docker run -i -t --rm \
-e TIMEZONE=Europe/Berlin \
-e MYSQL_ROOT_PASSWORD=test \
-e REPLICATION_PASSWORD=test \
-e NODE_NAME=node1 \
-e CLUSTER_NAME=test \
-e CLUSTER_ADDRESS=gcomm:// \
hauptmedia/mariadb:10.0-galera --wsrep-new-cluster
```

Join a node to the cluster:

```bash
docker run -i -t --rm \
-e TIMEZONE=Europe/Berlin \
-e MYSQL_ROOT_PASSWORD=test \
-e REPLICATION_PASSWORD=test \
-e NODE_NAME=node2 \
-e CLUSTER_NAME=test \
-e CLUSTER_ADDRESS=gcomm://ip1,ip2 \
hauptmedia/mariadb:10.0-galera
```

Please note: if you don't specify the timezone the server will run with UTC time
