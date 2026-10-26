*This project has been created as part of the 42 curriculum by cmanuel-*

# Inception

A small virtualized infrastructure: WordPress, MariaDB and NGINX, each running in its own container, built from custom Dockerfiles and orchestrated with Docker Compose.
As for the Project Bonus, you are asked to implement Adminer, FTP server, Redis, a static web page and an optional service at your choice (Portainer, in my case).

## Description

This project sets up a containerized stack where every service runs in a dedicated
container built from its own `Dockerfile` (base image: the penultimate stable Alpine,
`alpine:3.23` — no ready-made service images are pulled from Docker Hub).

**Mandatory services**

| Service | Role | Network |
|---|---|---|
| `nginx` | Single entry point of the infrastructure, **port 443 only**, TLSv1.2 / TLSv1.3 with a self-signed certificate for `cmanuel-.42.fr` | `inception` |
| `wordpress` | WordPress + php-fpm 8.4 only (no NGINX), auto-installed and configured at first boot via `wp-cli` | `inception` |
| `mariadb` | Database only, reachable exclusively from inside the network | `inception` |

**Persistence** — two Docker *named volumes*, both stored on the host under
`/home/cmanuel-/data/` (via `driver_opts: o=bind`):

- `db_data` → MariaDB datadir (`/var/lib/mysql`)
- `wp_data` → WordPress site files (`/var/www/html`)

**Docker network** — a user-defined bridge network (`inception`) connects the
containers; services discover each other by name (`mariadb`, `wordpress`). NGINX
talks to WordPress over FastCGI (`wordpress:9000`), WordPress talks to MariaDB
(`mariadb:3306`). No port of the database or php-fpm is published to the host —
only `443` is exposed.

**Configuration & secrets** — all configuration lives in `srcs/`
(`docker-compose.yml`, `.env`, per-service `requirements/<service>/`).
Every credential (DB passwords, WordPress admin/author passwords, FTP password)
is generated at setup time into `secrets/*.txt`, consumed by containers as
Docker **secrets** (`/run/secrets/...`) and never written into the repository
(`secrets/` and `srcs/.env` are gitignored).

**Main design choices**

- *Idempotent boot scripts*: the MariaDB entrypoint initializes the datadir only on
  first boot; the WordPress entrypoint seeds/configures/installs step by step with
  guards, so `restart: unless-stopped` reboots never wipe data.
- *PID-1 hygiene*: containers run the real daemon in the foreground
  (`nginx -g 'daemon off;'`, `php-fpm -F`, `mariadbd`, `vsftpd`), no `tail -f`
  or fake-background hacks.
- *One secret file per credential*, with two roles per line only where a pair is
  natural (`wp_credentials`: line 1 = admin password, line 2 = second-user password).

### VM vs Docker

A virtual machine emulates an entire *computer*: guest kernel, full OS boot,
GBs of RAM and disk reserved. A container shares the host kernel and isolates a
single *process tree* with its own filesystem, network and PID namespace —
startup is near-instant and memory is used only by the actual services. For this
project, the VM is the sandbox that hosts Docker; inside it, containers replace
"one heavy VM per service" with "one lightweight process per service", which is
what makes a 3-to-8-service stack cheap enough to rebuild and reboot freely.

### Secrets vs environment variables

Environment variables (`.env`) are convenient but leak: they appear in
`docker inspect`, in child-process environments and often in logs. They are good
for *non-sensitive* config (domain name, usernames, ports). Secrets are mounted by
Docker as files under `/run/secrets/` with strict permissions; they never enter
the image, the compose interpolation or the container environment, so a password
cannot be read via `inspect`/`logs`. Rule applied here: names → `.env`,
passwords → secrets.

### Docker network vs host network

`network_mode: host` puts the container directly on the host's network stack:
zero isolation, every service shares the host interface, port conflicts and any
container can sniff/reach everything. A user-defined bridge network gives each
container its own namespace, publishes only mapped ports, and — importantly for
this project — provides built-in DNS: containers resolve each other by service
name (`wordpress:9000`, `mariadb:3306`). That is what allows NGINX to be the only
entry point while the internals stay private.

### Docker volumes vs bind mounts

A bind mount hard-codes a host path into the service — fragile, host-specific and
easy to accidentally commit. A named volume is managed by Docker: services mount a
logical name (`db_data`), and the *location* is a property of the volume, not of the
compose file. We get indirection (portability, `docker volume` lifecycle) while
still satisfying the subject's requirement that data physically lives in
`/home/cmanuel-/data/`, because named volumes here use the `local` driver with
`driver_opts: {type: none, o: bind, device: $DATA/...}` — the best of both: named
volume semantics, bind storage location.

## Instructions

### at 42 Local Machine

clone the repo:
```
git clone <your_repo> inception
rsync -av inception ~/.env <VM_IP>:/home/<USERNAME>/
```

### at VM 

```sh
make            # build + start the mandatory stack (mariadb, wordpress, nginx)
make bonus      # instead: everything, including bonus services
```

Point your browser to **https://cmanuel-.42.fr** (`make` appends the hosts entry
if missing; needs `sudo`). Full stop/start/reset lifecycle and troubleshooting in
[USER_DOC.md](USER_DOC.md) and [DEV_DOC.md](DEV_DOC.md).

## Resources

- Docker & Docker Compose — docs.docker.com/engine, docs.docker.com/compose
- Alpine Linux Wiki (currently on maintenance due to security issues: CVE-2026-109618, CVE-2026-109619);
- WordPress — wordpress.org/documentation; wp-cli — wp-cli.org
- MariaDB — mariadb.com/kb; Alpine package index — pkgs.alpinelinux.org
- Peer discussions during implementation and self-testing
- YT videos from Nana (TechWorld with Nana) and Marek (Automation Avenue)

**Use of AI**: 
- review and debug the Makefile, compose file and Dockerfiles
- help with idempotency throughout the whole project 
- draft and proofread these documentation files
- nourishable discussion for learning purposes

