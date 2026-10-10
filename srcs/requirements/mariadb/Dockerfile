FROM alpine:3.23

RUN apk add --no-cache mariadb mariadb-client

COPY tools/main.sh /usr/local/bin/
RUN	chmod +x /usr/local/bin/main.sh

VOLUME /var/lib/mysql

EXPOSE 3306

ENTRYPOINT ["main.sh"]
