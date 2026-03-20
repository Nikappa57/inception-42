*This project has been created as part of the 42 curriculum by lgaudino.*

# Inception

## Description

Inception is a system administration project that deepens knowledge of Docker and containerization. The goal is to build a small infrastructure composed of three services — NGINX, WordPress, and MariaDB — each running in its own dedicated container, orchestrated via Docker Compose inside a virtual machine.

The stack exposes a WordPress website reachable at `https://lgaudino.42.fr` (port 443 only, TLS 1.2/1.3), with PHP-FPM handling PHP execution and MariaDB as the database backend. All containers are built from custom Dockerfiles based on Debian 12; no pre-built application images from DockerHub are used. Sensitive credentials are managed through Docker secrets and a local `.env` file, both excluded from the repository.

### Project Description

#### Services included

| Service   | Image base  | Role                                      |
|-----------|-------------|-------------------------------------------|
| nginx     | debian:12   | Reverse proxy, TLS termination (port 443) |
| wordpress | debian:12   | WordPress + PHP-FPM 8.2 (port 9000)       |
| mariadb   | debian:12   | Relational database (port 3306)           |

Two named Docker volumes persist data across restarts:
- `mariadb_data` — stores the MariaDB database files
- `wordpress_data` — stores the WordPress site files

Both are backed by directories on the host at `/home/lgaudino/data/`.

#### Virtual Machines vs Docker

A Virtual Machine runs a complete operating system with its own kernel on top of a hypervisor. This provides strong isolation but comes with significant overhead, since every hardware request must pass through the hypervisor layer.

Docker containers share the host kernel directly through a container engine (like Docker Engine), which acts as an isolation layer without emulating hardware. Containers do not have their own kernel — all system calls go directly to the host kernel. This results in lower overhead, faster startup, and more efficient resource usage. The tradeoff is slightly less isolation compared to VMs.

#### Secrets vs Environment Variables

Environment variables (`.env` file) store non-sensitive configuration like the domain name, database name, and usernames. They are readable by any process in the container and, in a misconfigured setup, could end up in logs or `docker inspect` output.

Docker secrets are the recommended way to handle sensitive data such as passwords. They are mounted as in-memory files inside containers at `/run/secrets/`, accessible only to the containers that explicitly declare them. They never appear in environment variables or image layers. In this project, `db_password`, `db_root_password`, and `credentials` are managed as Docker secrets.

#### Docker Network vs Host Network

With `network: host`, a container shares the host's network interface directly — no isolation, no NAT. This is forbidden in this project.

A Docker bridge network (`driver: bridge`) creates a virtual private network between containers. Each container gets its own IP within that network and can reach other containers by service name (DNS resolution provided by Docker). External traffic only enters through explicitly published ports. This project uses a single bridge network called `inception_network`, allowing nginx, wordpress, and mariadb to communicate privately while only port 443 is exposed to the outside.

#### Docker Volumes vs Bind Mounts

A bind mount maps a specific host path directly into a container. It is simple but tightly coupled to the host filesystem layout and not portable.

A Docker named volume is managed by the Docker engine, has a defined lifecycle independent from any container, and survives container removal. It is the recommended approach for persistent data. This project uses named volumes (`mariadb_data`, `wordpress_data`) configured to store data under `/home/lgaudino/data/` on the host, satisfying both the named volume requirement and the required host path.

## Instructions

### Prerequisites

- A Linux virtual machine with Docker and Docker Compose installed
- `make` available on the host
- The domain `lgaudino.42.fr` must resolve to the VM's IP (add an entry to `/etc/hosts` if needed):
  ```
  127.0.0.1   lgaudino.42.fr
  ```

### Secrets setup

Before the first run, create the `secrets/` directory at the root of the repository and populate it with three files (they are gitignored):

```
secrets/
  db_password.txt       # password for the MariaDB wordpress user
  db_root_password.txt  # password for the MariaDB root user
  credentials.txt       # WordPress admin and user credentials (sourced as env vars)
```

`credentials.txt` must export the following variables:

```bash
export WP_ADMIN_USER=<your_admin_username>   # must NOT contain "admin"
export WP_ADMIN_PASS=<your_admin_password>
export WP_ADMIN_EMAIL=<your_admin_email>
export WP_USER=<your_second_username>
export WP_USER_EMAIL=<your_second_user_email>
export WP_USER_PASS=<your_second_user_password>
```

### Environment file

Create `srcs/.env` with at least:

```env
LOGIN=lgaudino
DOMAIN_NAME=lgaudino.42.fr
MYSQL_DATABASE=wordpress_db
MYSQL_USER=lgaudino
```

### Build and run

```bash
make
```

This creates the required data directories and starts all services via `docker compose up --build`.

### Other Makefile targets

| Target   | Description                                      |
|----------|--------------------------------------------------|
| `make`   | Build images and start all containers            |
| `make stop`  | Stop containers without removing them        |
| `make start` | Restart stopped containers                   |
| `make down`  | Stop and remove containers                   |
| `make clean` | Remove containers and prune all Docker data  |
| `make fclean`| Full cleanup including volumes and data dirs |
| `make re`    | Full rebuild from scratch                    |

### Accessing the site

Once running, open `https://lgaudino.42.fr` in your browser. A self-signed certificate warning will appear — this is expected.

- WordPress site: `https://lgaudino.42.fr`
- WordPress admin panel: `https://lgaudino.42.fr/wp-admin`

## Resources

### Documentation

- [Docker official docs](https://docs.docker.com/)
- [Docker Hub — Debian](https://hub.docker.com/_/debian)
- [Docker Hub — MariaDB](https://hub.docker.com/_/mariadb)
- [MariaDB installation guide](https://mariadb.com/docs/server/mariadb-quickstart-guides/installing-mariadb-server-guide)
- [WP-CLI installation](https://make.wordpress.org/cli/handbook/guides/installing/)
- [WP-CLI command reference](https://developer.wordpress.org/cli/commands/)
- [OpenSSL essentials](https://www.digitalocean.com/community/tutorials/openssl-essentials-working-with-ssl-certificates-private-keys-and-csrs)
- [NGINX beginner's guide](https://nginx.org/en/docs/beginners_guide.html)
- [Dockerfile reference](https://docs.docker.com/reference/dockerfile/)

### Tutorials

- [Docker per comuni mortali (Udemy)](https://www.udemy.com/course/docker-per-comuni-mortali)
- [Inception guide — 42 project (Medium)](https://medium.com/@ssterdev/inception-guide-42-project-part-i-7e3af15eb671)
- [Forstman1/inception-42 (GitHub)](https://github.com/Forstman1/inception-42)

### AI usage

Claude and Gemini were used during this project for code review, documentation and conceptual explanations.

