# MariaDB Defense Cheat-Sheet

> Ordered walkthrough for the defense. Commands assume the stack is up via `make up`.

## 1. Log into the database (graded)

Run the passwordless unix-socket login:

```bash
docker compose exec -it mariadb mariadb -u root
```

> **Explain:** the unix_socket plugin sees the exec ran as OS root, so it authenticates root@localhost. No password is ever sent.

## 2. Prove the DB is not empty

```sql
SHOW DATABASES;                        -- wordpress db listed
USE wordpress; SHOW TABLES;            -- ~12 wp_* tables after WP installs
SELECT User, Host FROM mysql.user;     -- root, mysql, WP app user
```

## 3. Show both root auth branches exist

```sql
SHOW CREATE USER 'root'@'localhost'\G
```

> `IDENTIFIED VIA unix_socket OR mysql_native_password USING '*'...`

## 4. Prove it answers over TCP

```bash
docker compose exec wordpress php -r 'new mysqli("mariadb","<user>","<pw>","wordpress"); echo "connected\n";'

# or from the mariadb container:
mariadb -h 127.0.0.1 -P 3306 -u <user> -p
```

## 5. Persistence (graded)

```bash
docker compose down && docker compose up -d
docker compose exec -it mariadb mariadb -u root -e "SELECT * FROM wordpress.wp_posts;"
docker volume ls && docker volume inspect inception_db_data
```

> The Mountpoint must show `/home/cgarrote/data/...`

## 6. Quick liveness

```bash
docker compose exec mariadb mariadb-admin ping
docker compose ps        # healthy status from the healthcheck
```
