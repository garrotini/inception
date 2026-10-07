FROM alpine:3.23

RUN apk add --no-cache nginx openssl \
	&& mkdir -p /etc/nginx/certs

RUN openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
	-subj "/CN=cmanuel-.42.fr" \
	-addext "subjectAltName=DNS:cmanuel-.42.fr,DNS:localhost,IP:127.0.0.1" \
	-keyout /etc/nginx/certs/server.key -out /etc/nginx/certs/server.crt

COPY default.conf /etc/nginx/http.d/default.conf
COPY index.html /var/www/htdocs/index.html

EXPOSE 443

CMD ["nginx", "-g", "daemon off;"]

