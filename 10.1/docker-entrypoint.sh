#!/bin/bash
set -e
DATADIR=/var/lib/mysql
IP=$(hostname --ip-address | cut -d" " -f1)


# set timezone if it was specified
if [ -n "$TIMEZONE" ]; then
	echo ${TIMEZONE} > /etc/timezone && \
	dpkg-reconfigure -f noninteractive tzdata
fi


# if command starts with an option, prepend mysqld
if [ "${1:0:1}" = '-' ]; then
	set -- mysqld "$@"
fi

if [ "$1" = 'mysqld' ]; then
	sed -i -e "s/^port.*=.*/port=${PORT}/" /etc/mysql/my.cnf 
	sed -i -e "s/^#max_connections.*=.*/max_connections=${MAX_CONNECTIONS}/" /etc/mysql/my.cnf 
	sed -i -e "s/^max_allowed_packet.*=.*/max_allowed_packet=${MAX_ALLOWED_PACKET}/" /etc/mysql/my.cnf 

	if [ -n "$GALERA" ]; then
		if [ -z "$CLUSTER_NAME" ]; then
			echo >&2 'error:  missing CLUSTER_NAME'
			echo >&2 '  Did you forget to add -e CLUSTER_NAME=... ?'
			exit 1
		fi
	
		if [ -z "$NODE_NAME" ]; then
			echo >&2 'error:  missing NODE_NAME'
			echo >&2 '  Did you forget to add -e NODE_NAME=... ?'
			exit 1
		fi
	
		if [ -z "$CLUSTER_ADDRESS" ]; then
			echo >&2 'error:  missing CLUSTER_ADDRESS'
			echo >&2 '  Did you forget to add -e CLUSTER_ADDRESS=... ?'
			exit 1
		fi
	else
		rm /etc/mysql/conf.d/galera.cnf
	fi

	
	if [ ! -d "$DATADIR/mysql" ]; then
		if [ -n "$GALERA" -a -z "$REPLICATION_PASSWORD" ]; then
			echo >&2 'error:  missing REPLICATION_PASSWORD'
			echo >&2 '  Did you forget to add -e REPLICATION_PASSWORD=... ?'
			exit 1
		fi
		
		echo 'Running mysql_install_db ...'
		mysql_install_db --datadir="$DATADIR"
		echo 'Finished mysql_install_db'
		
		tempSqlFile='/tmp/mysql-first-time.sql'
		cat > "$tempSqlFile" <<-EOSQL
			-- What's done in this file shouldn't be replicated
			--  or products like mysql-fabric won't work
			SET @@SESSION.SQL_LOG_BIN=0;
			
			DELETE FROM mysql.user ;
			CREATE USER 'root'@'%' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}' ;
			GRANT ALL ON *.* TO 'root'@'%' WITH GRANT OPTION;

			DROP DATABASE IF EXISTS test;
		EOSQL
		
		if [ -n "$GALERA" ]; then
			cat >> "$tempSqlFile" <<-EOSQL
			CREATE USER 'replication'@'%' IDENTIFIED BY '${REPLICATION_PASSWORD}';
			GRANT RELOAD,LOCK TABLES,REPLICATION CLIENT ON *.* TO 'replication'@'%';
			EOSQL
		fi

		if [ "$MYSQL_DATABASE" ]; then
			echo "CREATE DATABASE IF NOT EXISTS \`$MYSQL_DATABASE\` ;" >> "$tempSqlFile"
		fi
		
		if [ "$MYSQL_USER" -a "$MYSQL_PASSWORD" ]; then
			echo "CREATE USER '$MYSQL_USER'@'%' IDENTIFIED BY '$MYSQL_PASSWORD' ;" >> "$tempSqlFile"
			
			if [ "$MYSQL_DATABASE" ]; then
				echo "GRANT ALL ON \`$MYSQL_DATABASE\`.* TO '$MYSQL_USER'@'%' ;" >> "$tempSqlFile"
			fi
		fi
		
		echo 'FLUSH PRIVILEGES ;' >> "$tempSqlFile"
		
		set -- "$@" --init-file="$tempSqlFile"
	fi
	
	chown -R mysql:mysql "$DATADIR"


	if [ -n "$GALERA" ]; then
		# append galera specific run options

		set -- "$@" \
		--wsrep_cluster_name="$CLUSTER_NAME" \
		--wsrep_cluster_address="$CLUSTER_ADDRESS" \
		--wsrep_node_name="$NODE_NAME" \
		--wsrep_sst_auth="replication:$REPLICATION_PASSWORD" \
		--wsrep_sst_receive_address=$IP
	fi

	if [ -n "$LOG_BIN" ]; then
                set -- "$@" --log-bin="$LOG_BIN"
		chown mysql:mysql $(dirname $LOG_BIN)
	fi

        if [ -n "$LOG_BIN_INDEX" ]; then
                set -- "$@" --log-bin-index="$LOG_BIN_INDEX"
		chown mysql:mysql $(dirname $LOG_BIN)
        fi


fi

exec "$@"
