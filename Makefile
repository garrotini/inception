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
	sudo rm -rf ${DATA}/mariadb/*
	sudo rm -rf ${DATA}/wordpress/*
	# rm -rf ${DATA}/mariadb/*
	# rm -rf ${DATA}/wordpress/*
	docker volume prune -af

re: fclean all

tmaria:
	echo "___SHOW DATABASES___"
	docker exec mariadb mariadb -e "SHOW DATABASES;"
	echo "___SHOW GRANTS___"
	docker exec mariadb mariadb -e "SHOW GRANTS FOR 'dbuser';"
	echo "___SHOW GRANTS___"
	docker exec mariadb mariadb -e "SHOW GRANTS FOR 'root';"

shmaria:
	docker exec -it mariadb sh

shwp:
	docker exec -it wordpress sh

stop:
	docker ps -qa | xargs -r docker stop

.PHONY: all build up down clean fclean re tmaria shmaria stop
