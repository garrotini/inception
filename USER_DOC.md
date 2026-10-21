# USER_DOC — Inception

Audience: an end user / administrator of the stack. No development knowledge
required.

## 1. What this stack provides

| URL / endpoint | What you get |
|---|---|
| `https://cmanuel-.42.fr` | WordPress site (the only public entry point) |
| `https://cmanuel-.42.fr/wp-admin` | WordPress administration dashboard |
| `https://cmanuel-.42.fr:8080` (bonus) | Adminer — web UI for the MariaDB database |
| `https://cmanuel-.42.fr:9443` (bonus) | Portainer — container management UI |
| `http://cmanuel-.42.fr:8081` (bonus) | Static showcase site |
| `ftp://cmanuel-.42.fr:21` (bonus) | FTP server editing the WordPress files |

The first visit shows a **self-signed certificate warning** — that is expected;
accept/proceed once. Plain `http://` is intentionally *not* served: only TLS
(TLSv1.2/1.3) on port 443 answers.

## 2. Start and stop the stack

From the repository root (where the `Makefile` is):

```sh
make            # first use / normal start: build images if needed + start everything
make start      # start containers that already exist (fast path, e.g. after a reboot)
make stop       # stop containers but keep them (everything is preserved)
make down       # stop AND remove the containers + network (data is NOT deleted)
make re         # full factory reset of the stack + start again (see §5!)
make help       # list all commands
```

Bonus (adds redis, adminer, portainer, ftp, static site):

```sh
make bonus      # build everything + start all services
make bonusstart # start existing bonus containers only
```

## 3. Accounts and credentials (where they live)

Usernames are fixed in `srcs/.env`; **passwords are generated** into `secrets/`
at first `make` and never touch the repository.

| Login | Username | Password location |
|---|---|---|
| WordPress administrator | `capitan` (from `.env` → `WP_ADMIN`) | `secrets/credentials.txt`, **line 1** |
| WordPress author user | `user` (from `.env` → `WP_USER`) | `secrets/credentials.txt`, **line 2** |
| MariaDB database user | `dbuser` (from `.env` → `MARIADB_USER`) | `secrets/db_password.txt` |
| MariaDB `root` | `root` | `secrets/db_root_password.txt` |
| FTP user (bonus) | `ftpuser` (from `.env` → `FTP_USER`) | `secrets/ftp_password.txt` |

```sh
cat secrets/credentials.txt        # line 1 = admin password, line 2 = author password
```

If a secrets file is missing it will be regenerated with a *new* random password
the next time you run `make` (or `make bonusrun`). To rotate on purpose, delete
the file and restart the related containers:

```sh
rm secrets/credentials.txt
make down && make                  # a fresh admin/author password is generated
```

> Note: after deleting `credentials.txt`, the *old* admin password still works on
> an existing database — WordPress only creates users on first install. A full
> `make re` (data wiped) is required for the new passwords to take effect.

## 4. Basic health checks

```sh
docker compose -f srcs/docker-compose.yml ps     # all services "running/healthy"
docker compose -f srcs/docker-compose.yml logs --tail=50 nginx
curl -k https://cmanuel-.42.fr                   # HTML of your WordPress page
curl -I http://cmanuel-.42.fr                    # must FAIL (no HTTP listener) — expected
docker exec mariadb mariadb -e "SHOW DATABASES;" # 'wordpress' database exists
```

If the site is unreachable, check `srcs/.env` `DOMAIN_NAME` and the hosts entry
(`grep 42.fr /etc/hosts`) first.

## 5. Persistence — what survives, what doesn't

- **Survives everything short of `fclean`**: database content and site files live
  in Docker named volumes stored on the host under `/home/cmanuel-/data/`
  (`mariadb/`, `wordpress/`). Rebooting the VM, `make stop`, `make down` — all
  comments, pages and users come back.
- **`make re` / `make fclean` delete them**: the data directories under
  `/home/cmanuel-/data/` are wiped and WordPress reinstalls itself on next start.
  `fclean` also rotates the FTP password; the DB/WP secret files themselves are
  kept (see DEV_DOC for the credential lifecycle).
