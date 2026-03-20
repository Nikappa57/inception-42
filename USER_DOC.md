# User Documentation — Inception

## Services provided by the stack

This project runs three services inside Docker containers, all connected through a private Docker network:

| Service   | Description                                                                 |
|-----------|-----------------------------------------------------------------------------|
| **nginx**     | Web server and reverse proxy. The only entry point from the outside, accessible on port 443 (HTTPS/TLS). |
| **wordpress** | WordPress CMS with PHP-FPM. Serves the website and handles PHP execution. Not directly reachable from outside. |
| **mariadb**   | Relational database storing all WordPress content. Not directly reachable from outside. |

## Starting and stopping the project

### Start (first time or after a full clean)

```bash
make
```

This builds the Docker images and starts all containers. On the first run, WordPress and the database will be initialized automatically.

### Stop containers (without losing data)

```bash
make stop
```

### Start previously stopped containers

```bash
make start
```

### Stop and remove containers (data is preserved in volumes)

```bash
make down
```

### Full cleanup (removes containers, images, volumes, and data directories)

```bash
make fclean
```

## Accessing the website and administration panel

Make sure the domain resolves to the VM's IP. If needed, add this line to `/etc/hosts` on the machine you are browsing from:

```
<VM_IP_ADDRESS>   lgaudino.42.fr
```

| URL | Description |
|-----|-------------|
| `https://lgaudino.42.fr` | WordPress website |
| `https://lgaudino.42.fr/wp-login.php` | WordPress login page |
| `https://lgaudino.42.fr/wp-admin` | WordPress administration panel |

A browser warning about the SSL certificate will appear — this is expected because the certificate is self-signed. Proceed past the warning to access the site.

The site is only accessible via HTTPS (port 443). Attempting to connect via HTTP (port 80) will not work.

## Locating and managing credentials

All credentials are stored locally in the `secrets/` directory at the root of the repository. This directory is excluded from Git for security reasons.

| File | Contents |
|------|----------|
| `secrets/db_password.txt` | Password for the MariaDB WordPress user |
| `secrets/db_root_password.txt` | Password for the MariaDB root user |
| `secrets/credentials.txt` | WordPress admin username, password, email, and second user details |

To change a password or credential, edit the corresponding file and then fully rebuild the stack:

```bash
make fclean
make
```

## Checking that services are running correctly

### View running containers

```bash
docker compose -f srcs/docker-compose.yml ps
```

All three containers (`nginx`, `wordpress`, `mariadb`) should appear with status `running`.

### View logs

```bash
# All services
docker compose -f srcs/docker-compose.yml logs

# A specific service, following new output
docker logs -f nginx
docker logs -f wordpress
docker logs -f mariadb
```

### Test HTTPS access

```bash
curl -k https://lgaudino.42.fr
```

Should return the WordPress HTML content.

### Verify TLS version

```bash
openssl s_client -connect lgaudino.42.fr:443 2>/dev/null | grep "Protocol"
```

Should show `TLSv1.2` or `TLSv1.3`.

### Inspect the database

```bash
docker exec -it mariadb bash
mariadb -u root -p
# enter the root password from secrets/db_root_password.txt

SHOW DATABASES;
USE wordpress_db;
SHOW TABLES;
SELECT user_login, user_email FROM wp_users;
```
