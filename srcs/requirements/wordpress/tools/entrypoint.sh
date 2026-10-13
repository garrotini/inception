#!/bin/sh

set -e

MARIADB_PASSWORD="$(cat /run/secrets/db_password)"
WP_ADMIN_PASSWORD="$(sed -n 1p /run/secrets/wp_credentials)"
WP_USER_PASSWORD="$(sed -n 2p /run/secrets/wp_credentials)"

# setup mariadb client
echo "_ Config MariaDB... "

i=0
until mariadb-admin ping --host="$MARIADB_HOST" \
    --user="$MARIADB_USER" \
    --password="$MARIADB_PASSWORD" \
    --silent >/dev/null 2>&1; do
    i=$((i + 1))
    [ "$i" -ge 60 ] && { echo "ERROR: mariadb unreachable after 60s" >&2; exit 1; }
    sleep 1
done

echo "___ MariaDB is ready! ___ "

# setup WP
# first boot: seed the (empty) volume from the baked copy outside the mount point
if [ ! -f /var/www/html/wp-load.php ]; then
	echo "_ Seeding WordPress files into the volume..."
	cp -a /var/www-src/wordpress/. /var/www/html/
fi

if [ ! -f /var/www/html/wp-config.php ]; then
	echo "_ Config WordPress..."
	cd /var/www/html
	cp wp-config-sample.php wp-config.php
	sed -i "s/database_name_here/$MARIADB_DATABASE/" wp-config.php
    sed -i "s/username_here/$MARIADB_USER/" wp-config.php
    sed -i "s/password_here/$MARIADB_PASSWORD/" wp-config.php
    sed -i "s/localhost/$MARIADB_HOST/" wp-config.php
	wp config shuffle-salts --allow-root >/dev/null

	wp core install --url="https://$DOMAIN_NAME" \
		--admin_user="$WP_ADMIN" \
		--admin_email="$WP_ADMIN_EMAIL" \
		--admin_password="$WP_ADMIN_PASSWORD" \
		--title="$WP_TITLE" \
		--skip-email \
		--allow-root

    wp user create "$WP_USER" "$WP_USER_EMAIL" \
        --user_pass="$WP_USER_PASSWORD" \
        --role=author \
        --allow-root

	echo "___ WordPress has been configured ready! ___ "
else
	echo "___ WordPress should be running fine ___";
fi

# --- Redis object cache (bonus): only when WP_REDIS=true ---
cd /var/www/html

if [ "$WP_REDIS" = "true" ]; then
	echo "_ Configuring Redis object cache..."
	REDIS_HOST="${WP_REDIS_HOST:-redis}"
	REDIS_PORT="${WP_REDIS_PORT:-6379}"

	# wait for Redis (4 tries) — no depends_on, so it may still be starting
	i=0
	until nc -z "$REDIS_HOST" "$REDIS_PORT" 2>/dev/null; do
		i=$((i + 1))
		[ "$i" -ge 4 ] && break
		sleep 1
	done

	if nc -z "$REDIS_HOST" "$REDIS_PORT" 2>/dev/null; then
		wp config set WP_REDIS_HOST "$REDIS_HOST" --allow-root
		wp config set WP_REDIS_PORT "$REDIS_PORT" --raw --allow-root

		if ! wp plugin is-installed redis-cache --allow-root 2>/dev/null; then
			wp plugin install redis-cache --activate --allow-root
		fi
		wp redis enable --allow-root || true
		echo "_ Redis cache enabled"
	else
		echo "_ Redis not reachable - continuing without cache"
	fi
else
	echo "_ WP_REDIS not true - running without Redis cache"
	wp redis disable --allow-root 2>/dev/null || true
fi

chown -R www-data:www-data /var/www/html

exec php-fpm84 -F

