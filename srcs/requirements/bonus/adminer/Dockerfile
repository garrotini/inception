FROM alpine:3.23

RUN apk add --no-cache \
    php84 \
    php84-session \
    php84-mysqli \
	ca-certificates

# RUN mkdir -p /var/www \
# 	&& wget -qO /var/www/index.php https://www.adminer.org/latest.php
RUN mkdir -p /var/www \
	&& wget -qO /var/www/index.php https://github.com/vrana/adminer/releases/download/v6.1.2/adminer-6.1.2.php

EXPOSE 8080

CMD ["php84", "-S", "0.0.0.0:8080", "-t", "/var/www"]


