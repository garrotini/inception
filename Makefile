COMPOSE_FILE = ./srcs/docker-compose.yml
DATA = /home/cmanuel-/data
STAMP = .build.stamp
BONUS_STAMP  = .bonus.stamp
FTP_SECRET = secrets/ftp_password.txt

BONUS_SERVICES = static adminer portainer redis ftp

# --- mandatory --- 


all: $(STAMP) up

$(STAMP): srcs/docker-compose.yml $(shell find srcs/requirements -type f)
	mkdir -p ${DATA}/mariadb ${DATA}/wordpress
	docker compose -f ${COMPOSE_FILE} build
	@touch $(STAMP)

build:
	mkdir -p ${DATA}/mariadb ${DATA}/portainer ${DATA}/redis ${DATA}/wordpress
	docker compose -f ${COMPOSE_FILE} build

up:
	docker compose -f ${COMPOSE_FILE} up -d mariadb wordpress nginx

down:
	docker compose -f ${COMPOSE_FILE} down

clean:
	docker compose -f ${COMPOSE_FILE} down -v --remove-orphans
	docker system prune -af

fclean: clean
	sudo rm -rf ${DATA}
	rm -f $(FTP_SECRET)
	rm -f $(STAMP) $(BONUS_STAMP)
	docker volume prune -af

re: fclean all

first:
	mkdir -p secrets
	@umask 077 && openssl rand -hex 16 > ./secrets/db_password.txt
	@umask 077 && openssl rand -hex 16 > ./secrets/db_root_password.txt
	@umask 077 && openssl rand -hex 16 > ./secrets/credentials.txt
	@umask 077 && openssl rand -hex 16 >> ./secrets/credentials.txt
	cp srcs/_example srcs/.env
	echo "127.0.0.1	cmanuel-.42.fr" | sudo tee -a /etc/hosts

# --- bonus --- 

bonus: all $(FTP_SECRET) $(BONUS_STAMP) up-bonus

$(FTP_SECRET):
	mkdir -p secrets
	@umask 077 && openssl rand -hex 16 > $@

$(BONUS_STAMP): srcs/docker-compose.yml $(shell find srcs/requirements/bonus -type f)
	mkdir -p ${DATA}/mariadb ${DATA}/portainer ${DATA}/redis ${DATA}/wordpress ${DATA}/portainer ${DATA}/redis
	docker compose -f $(COMPOSE_FILE) build $(BONUS_SERVICES)
	@touch $(BONUS_STAMP)

rebonus: fclean bonus

up-bonus:
	WP_REDIS=true docker compose -f $(COMPOSE_FILE) up -d

# --- tests --- 

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

shredis:
	docker exec -it redis redis-cli

alpine:
	docker run --rm -it alpine:3.23 sh

stop:
	docker ps -qa | xargs -r docker stop

.PHONY: all build up bonus up-bonus down clean fclean re ffclean tmaria shmaria twp shwp stop secrets

