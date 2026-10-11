#!/bin/sh

set -e

DATADIR=/var/lib/mysql

MARIADB_PASSWORD=$(cat /run/secrets/db_password)
MARIADB_ROOT_PASSWORD=$(cat /run/secrets/db_root_password)

# runtime dirs — ran EVERY boot
mkdir -p /run/mysqld
chown -R mysql:mysql /run/mysqld
chmod 755 /run/mysqld

# phase 1 - init first time
if [ ! -d "$DATADIR/mysql" ]; then
	echo "First boot: initializing datadir...";
	mkdir -p /run/mysqld "$DATADIR"
	chown -R mysql:mysql "$DATADIR"
	mariadb-install-db --user=mysql --datadir="$DATADIR" --skip-test-db

	cat > /tmp/init.sql <<-EOF
		CREATE DATABASE IF NOT EXISTS ${MARIADB_DATABASE};
		ALTER USER 'root'@'localhost' IDENTIFIED VIA unix_socket OR mysql_native_password USING PASSWORD('$MARIADB_ROOT_PASSWORD');
		CREATE USER IF NOT EXISTS '$MARIADB_USER'@'%' IDENTIFIED BY '$MARIADB_PASSWORD';
        GRANT ALL PRIVILEGES ON $MARIADB_DATABASE.* TO '$MARIADB_USER'@'%';
        FLUSH PRIVILEGES;
	EOF
	chmod 600 /tmp/init.sql;
	mariadbd --user=mysql --datadir="$DATADIR" --bootstrap < /tmp/init.sql;
	rm -f /tmp/init.sql;
fi

# phase 2 - run forever
exec mariadbd --user=mysql --datadir="$DATADIR" --bind-address=0.0.0.0 --port=3306


