FROM alpine:3.23

RUN apk add --no-cache lighttpd

COPY html /var/www/localhost/htdocs

EXPOSE 8081

CMD ["lighttpd", "-D", "-f", "/etc/lighttpd/lighttpd.conf"]
# CMD ["lighttpd", "-D"]

