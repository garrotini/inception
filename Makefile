COMPOSE_FILE = ./srcs/docker-compose.yml
DATA = /home/cmanuel-/data
STAMP = .build.stamp
BONUS_STAMP  = .bonus.stamp
FTP_SECRET = secrets/ftp_password.txt

BONUS_SERVICES = static adminer portainer redis ftp

# --- mandatory --- 

all:
	@echo "\nUsage: make [OPTION]\n";
	@echo "make env	- create the credentials and environment"
	@echo "make build	- create the mandatory images: mariadb, wordpress, nginx"
	@echo "make run	- create and run the mandatory containers: mariadb, wordpress, nginx"
	@echo "make start	- start services"
	@echo "make stop	- stop services"
	@echo "make up		- create and start containers"
	@echo "make down	- stop and remove containers and networks"
	@echo "make bonus	- create ALL images (mandatory + bonus)"
	@echo "make bonusrun	- create and run the ALL containers"
	@echo "make bonusup	- create and start ALL containers"
	@echo "make bonusstart	- start ALL services"
	@echo "make re		- full clean, rebuild and run mandatory services"
	@echo "make rebonus	- full clean, rebuild and run ALL services"
	@echo "make clean	- stop and remove services + networks, purge images"
	@echo "make fclean	- stop and remove services + networks, purge images and remove persistent volumes"

env:
	mkdir -p secrets
	@umask 077 && openssl rand -hex 16 > ./secrets/db_password.txt
	@umask 077 && openssl rand -hex 16 > ./secrets/db_root_password.txt
	@umask 077 && openssl rand -hex 16 > ./secrets/credentials.txt
	@umask 077 && openssl rand -hex 16 >> ./secrets/credentials.txt
	cp srcs/_example srcs/.env
	echo "127.0.0.1	cmanuel-.42.fr" | sudo tee -a /etc/hosts

build: 
	mkdir -p ${DATA}/mariadb ${DATA}/wordpress
	docker compose -f ${COMPOSE_FILE} build mariadb wordpress nginx

run: 
	mkdir -p ${DATA}/mariadb ${DATA}/wordpress
	docker compose -f ${COMPOSE_FILE} run mariadb wordpress nginx

up:
	mkdir -p ${DATA}/mariadb ${DATA}/wordpress
	docker compose -f ${COMPOSE_FILE} up -d mariadb wordpress nginx

down:
	docker compose -f ${COMPOSE_FILE} down

clean:
	docker compose -f ${COMPOSE_FILE} down -v --remove-orphans
	docker system prune -af

fclean: clean
	sudo rm -rf ${DATA}
	rm -f $(FTP_SECRET)
	docker volume prune -af

re: fclean run

# --- bonus --- 

bonus: env $(FTP_SECRET)
	mkdir -p ${DATA}/mariadb ${DATA}/wordpress ${DATA}/portainer ${DATA}/redis
	docker compose -f $(COMPOSE_FILE) build

$(FTP_SECRET):
	mkdir -p secrets
	@umask 077 && openssl rand -hex 16 > $@

bonusrun: bonus
	WP_REDIS=true docker compose -f ${COMPOSE_FILE} up -d

bonusup:
	WP_REDIS=true docker compose -f ${COMPOSE_FILE} up -d

rebonus: fclean bonusrun

up-bonus:
	WP_REDIS=true docker compose -f $(COMPOSE_FILE) up -d

# --- tests/sh access --- 

tmaria:
	echo "___SHOW DATABASES___"
	docker exec mariadb mariadb -e "SHOW DATABASES;"
	echo "___SHOW GRANTS___"
	docker exec mariadb mariadb -e "SHOW GRANTS FOR 'dbuser';"

shmaria:
	docker exec -it mariadb sh

shwp:
	docker exec -it wordpress sh

shredis:
	docker exec -it redis redis-cli

alpine:
	docker run --rm -it alpine:3.23 sh

stop:
	docker ps -qa | xargs -r docker stop

.PHONY: all build up bonus up-bonus down clean fclean re ffclean tmaria shmaria twp shwp stop secrets

