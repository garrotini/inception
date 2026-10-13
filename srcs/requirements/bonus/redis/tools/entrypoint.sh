#!/bin/sh
set -e

# pure cache: reachable on the bridge, no password, AOF persistence and snapshots
# bind 0.0.0.0 -> communication with every container inside the inception network
# AOF (Append-Only File) persistence:
# it logs every write operation, ensuring minimal data loss in case of a crash.
# `save 900 1` -> after 900 seconds (15 minutes), if at least 1 key has changed, take a snapshot!
# `dir` sets the working directory where Redis will save RDB/AOF files
#

cat > /etc/redis.conf <<CONF
bind 0.0.0.0
port 6379
protected-mode no
maxmemory 256mb
appendonly yes
maxmemory-policy allkeys-lru
save 900 1
logfile /var/log/redis/redis-server.log
dir /var/lib/redis/
CONF

exec redis-server /etc/redis.conf
