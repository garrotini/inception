#!/bin/sh

set -eu

FTP_PASSWORD=$(cat /run/secrets/ftp_password)

echo "$FTP_USER:$FTP_PASSWORD" | chpasswd

echo "[ftp] ready: user=$FTP_USER home=/var/www/html"
exec vsftpd /etc/vsftpd/vsftpd.conf
