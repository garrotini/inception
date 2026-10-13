COMPOSE_FILE = ./srcs/docker-compose.yml
DATA = /home/cmanuel-/data

all: build up

build:
	mkdir -p ${DATA}/mariadb ${DATA}/wordpress
	docker compose -f ${COMPOSE_FILE} build mariadb wordpress nginx

up:
	docker compose -f ${COMPOSE_FILE} up -d mariadb wordpress nginx

down:
	docker compose -f ${COMPOSE_FILE} down

clean:
	docker compose -f ${COMPOSE_FILE} down -v --remove-orphans
	docker system prune -af

fclean: clean
	sudo rm -rf ${DATA}/mariadb
	sudo rm -rf ${DATA}/wordpress
	sudo rm -rf {DATA}
	docker volume prune -af

re: fclean all

tmaria:
	echo "___SHOW DATABASES___"
	docker exec mariadb mariadb -e "SHOW DATABASES;"
	echo "___SHOW GRANTS___"
	docker exec mariadb mariadb -e "SHOW GRANTS FOR 'dbuser';"

shmaria:
	docker exec -it mariadb sh

twp:
	echo "___WP-CLI & PHP___"
	docker exec wordpress wp --info --allow-root
	echo "___IS WORDPRESS INSTALLED?___"
	-docker exec wordpress sh -c 'wp core is-installed --path=/var/www/html --allow-root && echo "yes" || echo "no"'
	echo "___USERS___"
	-docker exec wordpress wp user list --path=/var/www/html --allow-root --fields=ID,user_login,user_email,roles
	echo "___SITE URL & TITLE___"
	-docker exec wordpress sh -c 'wp option get siteurl --path=/var/www/html --allow-root; wp option get blogname --path=/var/www/html --allow-root'
	echo "___DB CONNECTION (should print 1)___"
	-docker exec wordpress wp db query "SELECT 1;" --path=/var/www/html --allow-root
	echo "___DB TABLES___"
	-docker exec wordpress wp db query "SHOW TABLES;" --path=/var/www/html --allow-root
	echo "___WP-CONFIG DB SETTINGS___"
	docker exec wordpress grep -E "DB_NAME|DB_USER|DB_HOST|table_prefix" /var/www/html/wp-config.php
	echo "___PHP-FPM PROCESSES___"
	docker exec wordpress ps
	echo "___HTTPS (localhost)___"
	-curl -sk -o /dev/null -w 'status: %{http_code}\n' https://localhost/
	echo "___WP-LOGIN VIA NGINX (domain from .env)___"
	-D=$$(sed -n 's/^DOMAIN_NAME=//p' srcs/.env); curl -sk --resolve "$$D:443:127.0.0.1" "https://$$D/wp-login.php" -o /dev/null -w "status: %{http_code}\n"

shwp:
	docker exec -it wordpress sh

stop:
	docker ps -qa | xargs -r docker stop

.PHONY: all build up down clean fclean re tmaria shmaria twp shwp stop
