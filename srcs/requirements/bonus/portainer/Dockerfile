FROM alpine:3.23

RUN apk add --no-cache ca-certificates

ARG PORTAINER_VERSION=2.45.2

RUN wget -qO /tmp/portainer.tar.gz \
      "https://github.com/portainer/portainer/releases/download/${PORTAINER_VERSION}/portainer-${PORTAINER_VERSION}-linux-amd64.tar.gz" \
 && tar -xzf /tmp/portainer.tar.gz -C /tmp \
 && mv /tmp/portainer/portainer /portainer \
 && mv /tmp/portainer/public /public \
 && mv /tmp/portainer/mustache-templates /mustache-templates \
 && chmod +x /portainer \
 && rm -rf /tmp/portainer.tar.gz /tmp/portainer

VOLUME /data
EXPOSE 9443

ENTRYPOINT ["/portainer"]

