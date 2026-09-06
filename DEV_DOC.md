# 🛠️ Inception — Developer Documentation (`DEV_DOC.md`)

This technical documentation provides engineers and evaluators with in-depth instructions regarding environment setup, build pipelines, directory structures, Docker Compose mechanics, and persistence mechanics.

---

## 1. System Prerequisites

The Inception project requires a Linux environment (Debian Bookworm or Ubuntu 24.04 LTS).

- **Docker Engine**: `>= 24.0.0`
- **Docker Compose (v2 plugin or standalone)**: `>= 2.20.0`
- **GNU Make**: `>= 4.3`
- **Root / Sudo privileges**: Required for bind-mount host directory management (`/home/${USER}/data`) and updating `/etc/hosts`.

---

## 2. Environment Setup

### 2.1 Host DNS Resolution
Map the project domain to localhost by editing `/etc/hosts`:
```bash
echo "127.0.0.1 rhiguita.42.fr" | sudo tee -a /etc/hosts
```

### 2.2 Environment Configuration (`.env`)
Create `srcs/.env` based on the provided template:
```bash
cp srcs/.env.example srcs/.env
```
Ensure `INCEPTION_USER` matches your local Linux username so that data directories align:
```env
INCEPTION_USER=rhiguita
DOMAIN_NAME=rhiguita.42.fr
MYSQL_DATABASE=wordpress
MYSQL_USER=wp_user
WP_TITLE=Inception 42 Madrid
WP_ADMIN_USER=rhiguita_master
WP_ADMIN_EMAIL=rhiguita@student.42madrid.com
WP_USER=student
WP_EMAIL=student@student.42madrid.com
```

### 2.3 Docker Secrets Initialization
Create the plain text files inside `secrets/` (permissions `600` or `644`):
```bash
mkdir -p secrets
echo "SuperSecretPass123!" > secrets/db_password.txt
echo "RootSuperAdminPass456!" > secrets/db_root_password.txt
echo "WpMasterPass789!" > secrets/wp_admin_password.txt
```

---

## 3. Makefile Pipeline & Target Reference

All operations are abstracted via the root `Makefile`:

| Target | Description | Executed Command |
|---|---|---|
| `all` / `up` | Creates host storage directories, builds images from source, and starts containers | `docker-compose -f srcs/docker-compose.yml up -d --build` |
| `down` | Stops containers and removes the bridge network, leaving volumes intact | `docker-compose -f srcs/docker-compose.yml down` |
| `start` | Starts previously stopped containers without re-building | `docker-compose -f srcs/docker-compose.yml start` |
| `stop` | Pauses running containers | `docker-compose -f srcs/docker-compose.yml stop` |
| `status` | Lists running containers, exit codes, and health checks | `docker-compose -f srcs/docker-compose.yml ps` |
| `logs` | Streams live logs across all services | `docker-compose -f srcs/docker-compose.yml logs -f` |
| `clean` | Alias for `down` | `docker-compose -f srcs/docker-compose.yml down` |
| `fclean` | Destroys containers, images, volumes, and purges `/home/$(USER)/data` | `docker-compose down -v --rmi all && sudo rm -rf /home/$(USER)/data` |
| `re` | Executes `fclean` followed by `all` (fresh build from scratch) | `make fclean && make all` |

---

## 4. Docker Compose Mechanics & Direct Commands

If debugging without the `Makefile`, you can invoke `docker-compose` directly pointing to the configuration file:

```bash
# Build and run containers
docker-compose -f srcs/docker-compose.yml up -d --build

# Inspect running services
docker-compose -f srcs/docker-compose.yml ps

# Tail logs for a specific service (e.g. MariaDB)
docker-compose -f srcs/docker-compose.yml logs -f mariadb

# Execute an interactive shell inside a container
docker-compose -f srcs/docker-compose.yml exec wordpress bash
docker-compose -f srcs/docker-compose.yml exec mariadb bash
docker-compose -f srcs/docker-compose.yml exec nginx bash

# Access database directly inside MariaDB container
docker-compose -f srcs/docker-compose.yml exec mariadb mariadb -u root -p"$(cat secrets/db_root_password.txt)"
```

### Network Architecture
Services communicate via an isolated user-defined bridge network `inception_network`. No service uses `network_mode: host` or legacy `--link`.
- `mariadb`: Accessible only at `mariadb:3306` inside `inception_network`.
- `wordpress`: Accessible only at `wordpress:9000` (FastCGI) inside `inception_network`.
- `nginx`: Only service exposing ports (`443:443`) to the host.

To inspect network topology:
```bash
docker network ls
docker network inspect srcs_inception_network
```

---

## 5. Data Persistence Architecture

The project requires persistent storage on the host machine under `/home/<login>/data`. To comply with 42 evaluation rules while retaining Docker volume management capabilities, named volumes are configured using the local bind driver:

```yaml
volumes:
  mariadb_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /home/${INCEPTION_USER}/data/mariadb
  wordpress_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /home/${INCEPTION_USER}/data/wordpress
```

### Verification Commands
1. **List Volumes**:
   ```bash
   docker volume ls
   ```
2. **Inspect Volume Path**:
   ```bash
   docker volume inspect srcs_mariadb_data
   docker volume inspect srcs_wordpress_data
   ```
   Verify that the `Mountpoint` and `device` fields contain `/home/<login>/data/`.

3. **Reboot Persistence Test**:
   - Create content in WordPress or execute an SQL query inserting a record.
   - Restart the virtual machine or execute:
     ```bash
     make down
     make up
     ```
   - Verify that all database entries and uploads in `/home/${INCEPTION_USER}/data/` persist without data loss.

---

## 6. Live Configuration Modification (Defense Test)

During the evaluation, the evaluator will ask you to change a service configuration (e.g., port modification):

### Example: Modifying NGINX Port from 443 to 8443
1. Edit `srcs/requirements/nginx/conf/nginx.conf`:
   ```nginx
   listen 8443 ssl;
   listen [::]:8443 ssl;
   ```
2. Edit `srcs/docker-compose.yml` under `nginx`:
   ```yaml
   ports:
     - "8443:8443"
   ```
3. Rebuild and restart:
   ```bash
   make up
   ```
4. Verify accessibility on the new port:
   ```bash
   curl -k -I https://rhiguita.42.fr:8443
   ```
