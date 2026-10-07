#!/bin/sh

set -eu

DATADIR=/var/lib/mysql
ROOT_PASSWD=$(cat /run/secrets/db_root_password)
MYSQL_PASSWD=$(cat /run/secrets/db_password)

mkdir -p /run/mysqld
chown mysql:mysql /run/mysqld "$DATADIR"

# First run: datadir has no system tables
if [ ! -d "$DATADIR/mysql" ]; then
	mariadb-install-db --user=mysql --datadir="$DATADIR" --skip-test-db
	cat > /tmp/init.sql <<-EOF
		CREATE DATABASE IF NOT EXISTS $MYSQL_DATABASE;
		CREATE USER IF NOT EXISTS '$MYSQL_USER'@'%' IDENTIFIED BY '$MYSQL_PASSWD';
		GRANT ALL PRIVILEGES ON $MYSQL_DATABASE.* TO '$MYSQL_USER'@'%';
		ALTER USER 'root'@'localhost' IDENTIFIED VIA unix_socket OR mysql_native_password USING PASSWORD('$ROOT_PASSWD');
		FLUSH PRIVILEGES;
	EOF
	chown mysql:mysql /tmp/init.sql && chmod 600 /tmp/init.sql
	exec mariadbd --user=mysql --init-file=/tmp/init.sql
fi

echo "Starting MariaDB..."
exec mariadbd --user=mysql
