
all: b up

re: clean all

b:
	docker compose build wordpress

up:
	docker compose up -d wordpress

down:
	docker compose down wordpress

clean:
	docker compose down wordpress
	docker rm -f wordpress
	rm -rf home/cmanuel-/data/wordpress

sh:
	docker exec -it wordpress sh

alpine:
	docker run -it --rm alpine:3.23 sh
