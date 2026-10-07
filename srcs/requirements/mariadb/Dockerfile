FROM alpine:3.23

RUN apk add --no-cache mariadb mariadb-client

COPY conf/mariadb-server.cnf /etc/my.cnf.d/mariadb-server.cnf
COPY tools/entrypoint.sh /
RUN chmod +x /entrypoint.sh

EXPOSE 3306

VOLUME /var/lib/mysql

ENTRYPOINT ["sh", "entrypoint.sh"]
