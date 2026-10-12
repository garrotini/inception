#!/bin/sh

set -e

MARIADB_PASSWORD="$(cat /run/secrets/db_password)"
WP_ADMIN_PASSWORD="$(sed -n 1p /run/secrets/wp_credentials)"
WP_USER_PASSWORD="$(sed -n 2p /run/secrets/wp_credentials)"

# setup mariadb client
echo "_ Config MariaDB... "
until mariadb \
	--skip-ssl-verify-server-cert \
	--host=${MARIADB_HOST} \
	--port=3306 \
	--user=${MARIADB_USER} \
	--password=${MARIADB_PASSWORD} \
	--execute "SELECT 1 FROM information_schema.SCHEMATA WHERE SCHEMA_NAME='$MARIADB_DATABASE'" >/dev/null 2>&1
do
	echo "_ waiting for MariaDB... "
	sleep 1;
done

echo "___ MariaDB is ready! ___ "

# setup WP
if [ ! -f /var/www/html/wp-config.php ]; then
	echo "_ Config WordPress..."
	cd /var/www/html
	cp wp-config-sample.php wp-config.php
	sed -i "s/database_name_here/$MARIADB_DATABASE/" wp-config.php
    sed -i "s/username_here/$MARIADB_USER/" wp-config.php
    sed -i "s/password_here/$MARIADB_PASSWORD/" wp-config.php
    sed -i "s/localhost/$MARIADB_HOST/" wp-config.php

	wp core install --url="https://$DOMAIN_NAME" \
		--admin_user="$WP_ADMIN" \
		--admin_email="$WP_ADMIN_EMAIL" \
		--admin_password="$WP_ADMIN_PASSWORD" \
		--title="$WP_TITLE" \
		--allow-root

    wp user create "$WP_USER" "$WP_USER_EMAIL" \
        --user_pass="$WP_USER_PASSWORD" \
        --role=author \
        --allow-root
	echo "___ WordPress has been configured ready! ___ "
fi

echo "___ WordPress should be running fine ___"


exec php-fpm84 -F

