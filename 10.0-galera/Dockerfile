FROM		debian:jessie
MAINTAINER	Julian Haupt <julian.haupt@hauptmedia.de>

# add our user and group first to make sure their IDs get assigned consistently, regardless of whatever dependencies get added
RUN		groupadd -r mysql && useradd -r -g mysql mysql

ENV		DEBIAN_FRONTEND noninteractive

# install needed packages
RUN		apt-get update -qq && \
		apt-get upgrade --yes && \
		apt-get -y --no-install-recommends --no-install-suggests install host socat unzip ca-certificates wget curl python-software-properties && \
		apt-get clean autoclean && \
		apt-get autoremove --yes && \ 
		rm -rf /var/lib/{apt,dpkg,cache,log}/

ENV		MARIADB_MAJOR 10.0 
ENV		MARIADB_VERSION 10.0.17

# install mariadb
RUN		apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xcbcb082a1bb943db && \
		echo "deb http://ftp.hosteurope.de/mirror/mariadb.org/repo/${MARIADB_MAJOR}/debian wheezy main" >>/etc/apt/sources.list && \
		apt-get update -qq && \
		apt-get -y install percona-xtrabackup mariadb-galera-server-${MARIADB_MAJOR}="${MARIADB_VERSION}+maria-1~wheezy" mariadb-client-${MARIADB_MAJOR}="${MARIADB_VERSION}+maria-1~wheezy" && \
		apt-get clean autoclean && \
		apt-get autoremove --yes && \ 
		rm -rf /var/lib/{apt,dpkg,cache,log}/ && \
		rm -rf /var/lib/mysql && \
		mkdir /var/lib/mysql && \
		sed -ri 's/^(bind-address|skip-networking|log)/;\1/' /etc/mysql/my.cnf

ENV		GALERA_VERSION 25.3.9

# install galera
RUN		apt-get update -qq && \
		apt-get -y install galera-3="${GALERA_VERSION}-wheezy" && \
		apt-get clean autoclean && \
		apt-get autoremove --yes && \ 
		rm -rf /var/lib/{apt,dpkg,cache,log}/

# add configuration
ADD		conf.d/galera.cnf /etc/mysql/conf.d/galera.cnf

# 3306 - MySQL client connections
# 4567 - Galera Cluster replication traffic, multicast replication uses both udp & tcp
# 4568 - For Incremental State Transfers
# 4444 - For all other State Snapshot Transfers

EXPOSE		3306 4444 4567 4568

VOLUME		/var/lib/mysql
COPY		docker-entrypoint.sh /entrypoint.sh
ENTRYPOINT	["/entrypoint.sh"]

CMD ["mysqld"]
