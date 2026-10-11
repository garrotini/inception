FROM alpine:3.23

RUN apk add --no-cache mariadb mariadb-client

COPY tools/main.sh /usr/local/bin/
RUN	chmod +x /usr/local/bin/main.sh

RUN sed -i 's/skip-networking/#skip-networking/' /etc/my.cnf.d/mariadb-server.cnf

VOLUME /var/lib/mysql

EXPOSE 3306

ENTRYPOINT ["main.sh"]
