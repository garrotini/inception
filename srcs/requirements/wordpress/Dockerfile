FROM alpine:3.23

RUN apk update && apk add --no-cache \
	php84 \
	php84-fpm \
	php84-mysqli \
	php84-json \
	php84-curl \
	php84-dom \
	php84-mbstring \
	php84-openssl \
	php84-xml \
	php84-phar \
	php84-session \
	mariadb-client

# wp-cli will expect php, not php84
RUN ln -sf /usr/bin/php84 /usr/bin/php

# setup wp-cli
RUN wget -qO /usr/local/bin/wp https://github.com/wp-cli/wp-cli/releases/download/v2.12.0/wp-cli-2.12.0.phar && \
	chmod +x /usr/local/bin/wp

# setup wordpress
RUN mkdir -p /var/www/html
RUN wget https://wordpress.org/latest.zip && \
    unzip latest.zip && \
    cp -rf wordpress/* /var/www/html && \
    rm -rf wordpress latest.zip

# run wordpress under an unprivileged user
RUN set -x \
    && addgroup -g 82 -S www-data 2>/dev/null || true \
    && adduser -u 82 -D -S -G www-data www-data 2>/dev/null || true
RUN chown -R www-data:www-data /var/www/html

# copy config 
COPY conf/www.conf /etc/php84/php-fpm.d/www.conf

COPY tools/entrypoint.sh /
RUN	chmod +x /entrypoint.sh

EXPOSE 9000

ENTRYPOINT ["/entrypoint.sh"]

