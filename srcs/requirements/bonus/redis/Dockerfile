FROM alpine:3.23

RUN apk add --no-cache redis

COPY tools/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 6379
ENTRYPOINT ["/entrypoint.sh"]
