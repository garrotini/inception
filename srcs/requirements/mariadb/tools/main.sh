#!/bin/sh

set -e

DATADIR=/var/lib/mysql

# runtime dirs — ran EVERY boot
mkdir -p /run/mysqld
chown -R mysql:mysql /run/mysqld
chmod 755 /run/mysqld

# phase 1 - init first time
if [ ! -d "$DATADIR/mysql" ]; then
	echo "First boot: initializing datadir...";
	mkdir -p /run/mysqld "$DATADIR"
	chown -R mysql:mysql "$DATADIR"
	mariadb-install-db --user=mysql --datadir="$DATADIR" --auth-root-authentication-method=normal

	cat > /tmp/init.sql <<-EOF
        FLUSH PRIVILEGES;
		DROP DATABASE IF EXISTS test;
		CREATE DATABASE IF NOT EXISTS ${MARIADB_DATABASE};
		CREATE USER 'root'@'%' IDENTIFIED BY '$MARIADB_ROOT_PASSWORD';
        GRANT ALL ON *.* TO 'root'@'%' WITH GRANT OPTION;
		CREATE USER IF NOT EXISTS '$MARIADB_USER'@'%' IDENTIFIED BY '$MARIADB_PASSWORD';
        GRANT ALL PRIVILEGES ON $MARIADB_DATABASE.* TO '$MARIADB_USER'@'%';
        FLUSH PRIVILEGES;
	EOF
	mariadbd --user=mysql --datadir="$DATADIR" --bootstrap < /tmp/init.sql;
	rm -f /tmp/init.sql;
fi

# phase 2 - run forever
exec mariadbd --user=mysql --datadir="$DATADIR" --bind-address=0.0.0.0 --port=3306


