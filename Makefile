COMPOSE_FILE = ./srcs/docker-compose.yml
DATA = /home/cmanuel-/data

all: build up

build:
	make -p ${DATA}/{mariadb,wordpress}
	docker compose -f ${COMPOSE_FILE} build mariadb nginx

up:
	docker compose -f ${COMPOSE_FILE} up -d mariadb nginx

down:
	docker compose -f ${COMPOSE_FILE} down

clean:
	docker compose -f ${COMPOSE_FILE} down
	rm -rf ${DATA}

fclean: clean
	docker image rm -f mary

re: fclean all

t:
	echo "___SHOW DATABASES___"
	docker exec mary mariadb -e "SHOW DATABASES;"
	echo "___SHOW GRANTS___"
	docker exec mary mariadb -e "SHOW GRANTS FOR 'dbuser';"
	echo "___SHOW GRANTS___"
	docker exec mary mariadb -e "SHOW GRANTS FOR 'root';"

sh:
	docker exec -it mary sh

stop:
	docker stop mary

