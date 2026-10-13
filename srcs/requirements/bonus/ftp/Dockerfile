FROM alpine:3.23

RUN apk add --no-cache vsftpd

RUN addgroup -g 82 www-data 2>/dev/null || true \
 && adduser -u 82 -D -G www-data -H -h /var/www/html -s /sbin/nologin ftpuser

# vsftpd authenticates through PAM (privileged access management)
RUN mkdir -p /etc/pam.d \
 && printf 'auth    required /usr/lib/security/pam_unix.so\naccount required /usr/lib/security/pam_unix.so\n' > /etc/pam.d/vsftpd \
 && echo /sbin/nologin >> /etc/shells

COPY conf/vsftpd.conf /etc/vsftpd/vsftpd.conf
COPY tools/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 21 21000-21010

ENTRYPOINT ["/entrypoint.sh"]
