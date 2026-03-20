# Developer Documentation — Inception

## Environment setup from scratch

### Prerequisites

- A Linux virtual machine (the project must run inside a VM)
- Docker Engine installed: https://docs.docker.com/engine/install/
- Docker Compose plugin (included with Docker Engine on recent versions)
- `make`
- `git`

Verify the installation:

```bash
docker --version
docker compose version
make --version
```

### Clone the repository

```bash
git clone https://github.com/Nikappa57/inception-42.git
cd inception-42
```

### Create the secrets directory

The `secrets/` directory is gitignored and must be created manually. It must contain three plain text files:

```bash
mkdir -p secrets
```

**`secrets/db_password.txt`** — password for the MariaDB application user:
```
your_db_password_here
```

**`secrets/db_root_password.txt`** — password for the MariaDB root user:
```
your_root_password_here
```

**`secrets/credentials.txt`** — WordPress credentials, sourced as shell variables by the WordPress entrypoint:
```bash
export WP_ADMIN_USER=lgaudino_wp      # must NOT contain "admin" or "administrator"
export WP_ADMIN_PASS=your_admin_pass
export WP_ADMIN_EMAIL=admin@lgaudino.42.fr
export WP_USER=wp_editor
export WP_USER_EMAIL=editor@lgaudino.42.fr
export WP_USER_PASS=your_user_pass
```

### Create the environment file

Create `srcs/.env` (gitignored):

```env
LOGIN=lgaudino
DOMAIN_NAME=lgaudino.42.fr
MYSQL_DATABASE=wordpress_db
MYSQL_USER=wp_user
```

### Configure DNS resolution

Add the following entry to `/etc/hosts` on the VM:

```
127.0.0.1   lgaudino.42.fr
```

## Building and launching the project

### Full build and start

```bash
make
```

This runs the following steps internally:
1. Creates `/home/lgaudino/data/mariadb` and `/home/lgaudino/data/wordpress` on the host
2. Runs `docker compose -f srcs/docker-compose.yml up --build`

Docker Compose reads `srcs/docker-compose.yml`, builds each image from its Dockerfile, and starts the three containers.

### Makefile targets reference

| Target       | Command executed                                                                 | Effect |
|--------------|----------------------------------------------------------------------------------|--------|
| `make`       | `docker compose up --build`                                                     | Build images and start containers |
| `make stop`  | `docker compose stop`                                                           | Stop containers, preserve state |
| `make start` | `docker compose start`                                                          | Restart stopped containers |
| `make down`  | `docker compose down`                                                           | Stop and remove containers |
| `make clean` | `down` + `docker system prune -a`                                               | Remove containers and all unused Docker data |
| `make fclean`| `down -v` + `rm -rf data/*` + `docker system prune -af`                        | Full wipe including volumes and host data |
| `make re`    | `fclean` + `all`                                                                | Complete rebuild from scratch |

## Managing containers and volumes

### View container status

```bash
docker compose -f srcs/docker-compose.yml ps
```

### Rebuild a single service without restarting others

```bash
docker compose -f srcs/docker-compose.yml build wordpress
docker compose -f srcs/docker-compose.yml up -d wordpress
```

### Execute a command inside a running container

```bash
docker exec -it nginx bash
docker exec -it wordpress bash
docker exec -it mariadb bash
```

### View logs

```bash
docker logs -f <container_name>
docker compose -f srcs/docker-compose.yml logs --follow
```

### List volumes

```bash
docker volume ls
docker volume inspect <volume_name>
```

### Prune everything (nuclear option)

```bash
docker stop $(docker ps -qa)
docker rm $(docker ps -qa)
docker rmi -f $(docker images -qa)
docker volume rm $(docker volume ls -q)
docker network rm $(docker network ls -q) 2>/dev/null
```

## Project structure

```
.
├── Makefile                        # Build entrypoint
├── README.md
├── USER_DOC.md
├── DEV_DOC.md
├── .gitignore
├── secrets/                        # Gitignored — created locally
│   ├── credentials.txt
│   ├── db_password.txt
│   └── db_root_password.txt
└── srcs/
    ├── .env                        # Gitignored — created locally
    ├── docker-compose.yml
    └── requirements/
        ├── nginx/
        │   ├── Dockerfile
        │   ├── conf/nginx.conf
        │   └── tools/entrypoint.sh
        ├── wordpress/
        │   ├── Dockerfile
        │   ├── conf/www.conf
        │   └── tools/entrypoint.sh
        └── mariadb/
            ├── Dockerfile
            ├── conf/mariadb.cnf
            └── tools/entrypoint.sh
```

## Data persistence

### Where data is stored

| Volume          | Host path                       | Container path       | Content                  |
|-----------------|---------------------------------|----------------------|--------------------------|
| `mariadb_data`  | `/home/lgaudino/data/mariadb`   | `/var/lib/mysql`     | MariaDB database files   |
| `wordpress_data`| `/home/lgaudino/data/wordpress` | `/var/www/html`      | WordPress site files     |

These are Docker named volumes configured with `driver: local` and `type: none` (backed by a host directory). Data persists across `docker compose down` and container restarts.

Data is only removed by `make fclean`, which explicitly deletes the contents of `/home/lgaudino/data/`.

### How initialization works

**MariaDB** (`entrypoint.sh`): On first start, if `/var/lib/mysql/mysql` does not exist, `mysql_install_db` is called to initialize the base tables. If the WordPress database does not yet exist, a temporary SQL file is generated and passed to `mysqld_safe` via `--init-file` to create the database, user, and set the root password. On subsequent starts, `mysqld_safe` is called directly.

**WordPress** (`entrypoint.sh`): On first start, if `wp-config.php` does not exist, WP-CLI downloads WordPress core, creates `wp-config.php` with the database connection details, installs WordPress (creating the admin user), and creates a second regular user. On subsequent starts the setup is skipped and PHP-FPM starts directly.

### Testing persistence

1. Make a change on the WordPress site (e.g., add a post)
2. Reboot the virtual machine
3. Run `make` again
4. Verify the change is still present at `https://lgaudino.42.fr`

## Service communication

```
Browser (HTTPS :443)
      │
      ▼
 [nginx container]  ──── FastCGI (port 9000) ────▶  [wordpress container]
                                                            │
                                                     MySQL (port 3306)
                                                            │
                                                            ▼
                                                   [mariadb container]
```

All inter-container communication happens over the `inception_network` bridge network. Container names (`nginx`, `wordpress`, `mariadb`) are used as hostnames within this network. Only port 443 is published to the host.
