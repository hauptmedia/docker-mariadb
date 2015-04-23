#!/bin/bash
set -e

# if command starts with an option, prepend mysqld
if [ "${1:0:1}" = '-' ]; then
	set -- mysqld "$@"
fi

if [ "$1" = 'mysqld' ]; then
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

	# read DATADIR from the MySQL config
	DATADIR="$("$@" --verbose --help 2>/dev/null | awk '$1 == "datadir" { print $2; exit }')"
	
	if [ ! -d "$DATADIR/mysql" ]; then
		if [ -z "$MYSQL_ROOT_PASSWORD" -a -z "$MYSQL_ALLOW_EMPTY_PASSWORD" ]; then
			echo >&2 'error: database is uninitialized and MYSQL_ROOT_PASSWORD not set'
			echo >&2 '  Did you forget to add -e MYSQL_ROOT_PASSWORD=... ?'
			exit 1
		fi

		if [ -z "$REPLICATION_PASSWORD" ]; then
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

			CREATE USER 'replication'@'%' IDENTIFIED BY '${REPLICATION_PASSWORD}';
			GRANT RELOAD,LOCK TABLES,REPLICATION CLIENT ON *.* TO 'replication'@'%';

			DROP DATABASE IF EXISTS test ;
		EOSQL
		
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

	else
		WSREP_START_POSITION="$("$@" --wsrep-recover --log-error=/dev/stdout 2>&1 | grep 'Recovered position' | awk '{print $NF}')" 
		echo WSREP: Using start position ${WSREP_START_POSITION}
		set -- "$@" --wsrep_start_position=${WSREP_START_POSITION}
	fi
	
	chown -R mysql:mysql "$DATADIR"

	set -- "$@" \
		--wsrep_cluster_name="$CLUSTER_NAME" \
		--wsrep_cluster_address="$CLUSTER_ADDRESS" \
		--wsrep_node_name="$NODE_NAME" \
		--wsrep_sst_auth="replication:$REPLICATION_PASSWORD" \
		--default-time-zone="+01:00"

fi

exec "$@"
