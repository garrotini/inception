# DEV_DOC — Inception

Audience: a developer picking up the project. Assumes nothing is installed except
Docker on the (virtual) machine.

## 1. Prerequisites

- Linux (a 42 VM is fine) with `docker` + `docker compose` v2 plugin, `make`,
  `openssl`, `sudo`.
- The stack itself pulls nothing at runtime: all service images are **built from
  `alpine:3.23`** (the only allowed pulls: Alpine base layers and, at build time,
  official tarballs — WordPress release, `wp-cli` phar, Portainer binary —
  downloaded inside the Dockerfiles).
- `login.42.fr` domain: the host must resolve `cmanuel-.42.fr` to the machine.
  `make env` appends the `/etc/hosts` entry for you (asks for the sudo password
  only the first time). If your login differs, update: `Makefile` (`env:`),
  `srcs/_example` (`DOMAIN_NAME`), `srcs/requirements/nginx/conf/default.conf`
  (`server_name`) and the certificate CN/SAN in
  `srcs/requirements/nginx/Dockerfile`.

## 2. Repository layout

```
.
├── Makefile                  # single entry point for everything
├── README.md USER_DOC.md DEV_DOC.md
├── secrets/                  # GENERATED, gitignored (0600 files)
│   ├── db_password.txt       # MariaDB user password
│   ├── db_root_password.txt  # MariaDB root password
│   ├── credentials.txt       # WP passwords: line 1 = admin, line 2 = author user
│   └── ftp_password.txt      # bonus FTP password
└── srcs/
    ├── docker-compose.yml    # services, network, named volumes, secrets
    ├── .env                  # GENERATED from _example (gitignored): non-secret config
    ├── _example              # tracked template of the above
    └── requirements/
        ├── nginx/            # Dockerfile + conf/default.conf (TLS 1.2/1.3, 443)
        ├── wordpress/        # Dockerfile + conf/www.conf + tools/entrypoint.sh
        ├── mariadb/          # Dockerfile + tools/main.sh
        └── bonus/            # redis | adminer | portainer | ftp | static
```

Interpolation note: `${DATA}` and friends inside `docker-compose.yml` are resolved
from `srcs/.env` (compose project directory).

## 3. Setup and run from scratch

```sh
git clone <repo> && cd repo
make            # env (secrets/.env/hosts) → build mandatory → up -d mandatory
open https://cmanuel-.42.fr        # self-signed warning → proceed
```

What `make` does step by step (all steps are idempotent — create-only-if-missing):

1. `env` — generates `secrets/*.txt` with `openssl rand -hex 16` (umask 077),
   copies `srcs/_example → srcs/.env`, adds the hosts entry.
2. `build` — `mkdir -p $DATA/{mariadb,wordpress}` then
   `docker compose -f srcs/docker-compose.yml build mariadb wordpress nginx`.
3. `up` — `docker compose up -d mariadb wordpress nginx`.

At boot: MariaDB initializes the datadir + users **only if absent**
(`tools/main.sh`), then runs `mariadbd` as PID 1. WordPress' entrypoint waits on
`mariadb-admin ping`, seeds core files into the volume, writes `wp-config.php`,
runs `wp core install` and creates the author user — each step guarded, so a
container restart never re-installs over real data.

## 4. Makefile targets

| Command | Effect |
|---|---|
| `make` / `make all` | mandatory stack: setup → build → `up -d` |
| `make help` | usage list |
| `make env` | (re)create missing secrets / `.env` / hosts entry |
| `make build` | build the 3 mandatory images |
| `make run` | `build` + `up -d` mandatory services |
| `make up` / `make down` | start existing / remove containers + network |
| `make start` / `make stop` | start / stop existing containers (compose-scoped) |
| `make clean` | `down -v --remove-orphans` + `docker system prune -af` |
| `make fclean` | `clean` + wipe `$DATA` + delete `ftp_password.txt` + volume prune |
| `make re` | `fclean` → `run` (mandatory, factory state) |
| `make bonus` | full bonus setup: env → build **all** images → `up -d` everything |
| `make bonusbuild` | ensure setup, then build all images (no start) |
| `make bonusrun` | `bonusbuild` + `up -d` everything |
| `make bonusup` | ensure setup (incl. ftp secret), start all **without** rebuilding |
| `make bonusstart` | start existing bonus/mandatory containers |
| `make rebonus` | `fclean` → `bonus` |
| `make tmaria / shmaria / shwp / shredis` | debug helpers (SQL peek, shells) |

## 5. Raw docker compose commands

All compose invocations need the file path (the compose file lives in `srcs/`):

```sh
COMPOSE="docker compose -f srcs/docker-compose.yml"
$COMPOSE ps | logs -f nginx | restart wordpress | config   # config validates+interpolates
$COMPOSE up -d --build nginx
docker network ls && docker network inspect inception
docker volume ls && docker volume inspect inception_db_data
docker exec -it wordpress sh        # wp-cli available: wp --allow-root …
```

Bonus toggle: the WordPress entrypoint enables the Redis object cache only when
`WP_REDIS=true` (set by `bonusrun`/`bonusup`; `make up` alone runs the mandatory
stack without touching redis).

## 6. Data & persistence

Named volumes declared in `srcs/docker-compose.yml` backed by the local driver
with bind options, so content lands in the host path required by the subject:

```
inception_db_data   →  /home/cmanuel-/data/mariadb    (mounted at /var/lib/mysql)
inception_wp_data   →  /home/cmanuel-/data/wordpress  (mounted at /var/www/html;
                        read-only in nginx, writable in wordpress + bonus ftp)
inception_portainer_data / inception_redis_data → /home/cmanuel-/data/{portainer,redis}
```

Verify with `docker volume inspect <name>` → `Mountpoint` resolves under
`/home/cmanuel-/data/`. Persistence survives: container recreation, VM reboot
(`restart: unless-stopped` or a manual `make start`). Destroyed by:
`make fclean` / `make re` (`sudo rm -rf $DATA`).

## 7. Credential lifecycle (deliberate design)

- Mandatory secrets (`db_*`, `credentials.txt`) **persist across `fclean`** so a
  rebuilt stack keeps the same DB/admin passwords (DB is re-initialized from the
  same files).
- `ftp_password.txt` is the **only** secret `fclean` deletes → the bonus FTP
  password rotates on each full reset, and `bonus`/`bonusup` regenerate it.
- To wipe identities too: `rm secrets/*.txt && make re` (WordPress then
  reinstalls with fresh passwords).
- Nothing sensitive is ever interpolated into compose env or committed:
  `secrets/` and `srcs/.env` are gitignored; passwords travel as
  `/run/secrets/*` files only.

## 8. Changing configuration (e.g. defense demo: move a port)

Example — serve NGINX on 8443 instead of 443:

1. edit `srcs/docker-compose.yml`: `ports: - "8443:443"`
2. also, change the `.env` file so that `DOMAIN_NAME=cmanuel-.42.fr:8443`
3. rebuild & restart the stack: `make` (or `docker compose -f srcs/docker-compose.yml up -d --build nginx`)
4. verify: `https://cmanuel-.42.fr:8443` works; container keeps listening on 443
   internally (nothing else changed — networks/links are by service name).

Same pattern for bonus ports (`8080/8081/9443/21/21000-21010`), the `WP_TITLE`,
domain (see §1) or WordPress version (`ARG WP_VERSION`).

## 9. Troubleshooting

- **`secret file not found`** → a file in `secrets/` is missing; run `make env`
  (or `make bonusup` for the ftp one).
- **`open /home/...: permission denied` from docker** → host dirs were created by
  the Makefile; after a manual `rm -rf /home/cmanuel-/data`, run `make` again.
- **WordPress "Establishing a database connection" error** → MariaDB still healthy
  but passwords rotated: restore the original secret files or `make re`.
- **502 from nginx** → `docker logs wordpress` (php-fpm `www.conf` listens on
  `9000` inside the network; check both containers are on `inception`).
- **`make help` shows the usage list**; `docker compose -f srcs/docker-compose.yml config`
  is the quickest way to see the resolved configuration.
