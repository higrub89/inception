*This project has been created as part of the 42 curriculum by rhiguita.*

# Inception — High-Availability Isolated Infrastructure with Docker Compose

[![CI Pipeline](https://github.com/higrub89/inception/actions/workflows/ci.yml/badge.svg)](https://github.com/higrub89/inception/actions/workflows/ci.yml)
[![Docker](https://img.shields.io/badge/Docker_Compose-v2-blue.svg)](https://docs.docker.com/compose/)
[![Base OS](https://img.shields.io/badge/Base_OS-Debian_Bookworm-red.svg)](https://www.debian.org/)
[![Security](https://img.shields.io/badge/Security-TLSv1.2%20%2F%20TLSv1.3-brightgreen.svg)](https://nginx.org/)
[![Database](https://img.shields.io/badge/Database-MariaDB_10.11-brown.svg)](https://mariadb.org/)
[![Application](https://img.shields.io/badge/Stack-WordPress_%2B_PHP--FPM_8.2-blueviolet.svg)](https://wordpress.org/)
[![42 School](https://img.shields.io/badge/42_Madrid-100%2F100_Validated-purple.svg)](https://www.42madrid.com/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

## Description

Inception is a System Administration project in the 42 curriculum designed to introduce learners to system virtualization using Docker. The goal is to build a multi-container, fully secure, and isolated web infrastructure from scratch using **Docker Compose** on a Debian-based virtual machine.

---

## 🏗️ Architecture Overview

The infrastructure consists of three main services running in their own dedicated containers, connected via a custom, private Docker network:

```mermaid
graph TD
    Client([Web Client]) -->|Port 443 (HTTPS)| Nginx[NGINX Container]
    
    subgraph Custom Network [inception_network]
        Nginx -->|Port 9000 (FastCGI)| WordPress[WordPress + PHP-FPM Container]
        WordPress -->|Port 3306 (SQL)| MariaDB[MariaDB Container]
    end

    subgraph Persistent Storage [Host: /home/rhiguita/data/]
        wordpress_vol[(wordpress_data)] <--->|Mounts to /var/www/html| WordPress
        mariadb_vol[(mariadb_data)] <--->|Mounts to /var/lib/mysql| MariaDB
    end

    subgraph Security Layer
        Secret1[db_root_password.txt] -.->|Mounted to /run/secrets/| MariaDB
        Secret2[db_password.txt] -.->|Mounted to /run/secrets/| MariaDB
        Secret2 -.->|Mounted to /run/secrets/| WordPress
        Secret3[wp_admin_password.txt] -.->|Mounted to /run/secrets/| WordPress
    end
```

### Services Summary

1. **NGINX**:
   - **Role**: Only entrypoint of the infrastructure.
   - **Port**: `443` (HTTPS) exposed to the host.
   - **Security**: Configured strictly with TLSv1.2 and TLSv1.3 protocols.
   - **Function**: Serves WordPress static assets and forwards dynamic PHP requests to the WordPress container.
2. **WordPress & PHP-FPM**:
   - **Role**: Application server.
   - **Port**: `9000` (FastCGI), accessible only within the internal Docker network.
   - **Configuration**: Runs PHP-FPM to execute WordPress scripts, downloading and configuring the site dynamically at startup via `wp-cli`.
3. **MariaDB**:
   - **Role**: Relational database.
   - **Port**: `3306`, accessible only within the internal Docker network.
   - **Security**: Credentials managed through Docker Secrets; listens on all network interfaces (`0.0.0.0`) to accept connections from WordPress.

---

## 📐 Design Choices & Architectural Comparisons

### 1. Virtual Machines vs. Docker

| Criteria | Virtual Machines (VMs) | Docker Containers |
| :--- | :--- | :--- |
| **Architecture** | Hypervisor-based. Each VM runs a full guest OS including its kernel. | Container-based. Shares the host OS kernel; containers run as isolated processes. |
| **Resource Usage**| High overhead. Requires pre-allocated RAM, CPU, and disk space for the guest OS. | Extremely low overhead. Dynamically allocates resources as needed. |
| **Startup Time** | Slow (minutes) due to complete guest OS boot sequence. | Near-instantaneous (seconds/milliseconds). |
| **Isolation** | Strong hardware-level isolation (more secure but heavier). | Process-level isolation via Linux namespaces and cgroups. |
| **Portability** | High, but VM images are massive (several gigabytes). | Extremely high, using lightweight, layered images (megabytes). |

**Choice for this project**: While the overall project runs inside a Debian Virtual Machine (to ensure environment consistency during evaluation), we utilize **Docker** to containerize individual services. This allows us to achieve service isolation without the massive resource cost of spawning multiple VMs.

---

### 2. Secrets vs. Environment Variables

- **Environment Variables (`.env`)**:
  - Environment variables are easily inspectable from the host using `docker inspect` or within the container shell (`env` command).
  - If a container is compromised or logs are leaked, environment variables are often exposed.
  - Recommended only for non-sensitive configuration data (e.g., domain names, database names, ports, user names).
- **Docker Secrets (`secrets/`)**:
  - Secrets are stored securely on the host and mounted as temporary files inside the container's memory space (at `/run/secrets/<secret_name>`).
  - They are never written to disk within the container's filesystem and do not show up in `docker inspect`.
  - Exposing secrets only to the containers that explicitly need them adheres to the *Principle of Least Privilege*.

**Choice for this project**: Non-sensitive settings (like `DOMAIN_NAME` or `MYSQL_DATABASE`) are defined in the `srcs/.env` file. Highly sensitive data (passwords and administrative credentials) are managed strictly via **Docker Secrets** using local files mapped to `/run/secrets/`.

---

### 3. Docker Network vs. Host Network

- **Host Network (`network_mode: host`)**:
  - The container shares the network stack of the host. The container's ports map directly to the host's ports.
  - No isolation between the host and the container.
  - Prohibited in this project as it bypasses the container boundaries and security constraints.
- **Docker Custom Network (Bridge)**:
  - Creates an isolated, private virtual bridge network (`inception_network`).
  - Containers inside this network can resolve each other by their service names (built-in DNS resolution).
  - Only ports explicitly exposed (e.g., NGINX port 443) are accessible from the host/external world. All other service ports (`3306`, `9000`) remain isolated.

**Choice for this project**: We define a dedicated bridge network in `docker-compose.yml`. Only Nginx exposes port `443` to the host, ensuring it remains the sole entrypoint.

---

### 4. Docker Volumes vs. Bind Mounts

- **Bind Mounts**:
  - Maps an exact, absolute directory path on the host directly into the container.
  - Can cause file permission conflicts between the host user and the container user.
  - Tied directly to the host filesystem structure, reducing portability.
- **Docker Named Volumes**:
  - Managed entirely by Docker. Data persists even when containers are destroyed or updated.
  - Docker handles file permissions automatically, preventing system conflicts.
  - Highly portable.
  - By using the `local` driver options in the named volume configuration, we can safely instruct Docker to store the data under `/home/rhiguita/data` without resorting to basic host bind mounts.

**Choice for this project**: We use named volumes (`wordpress_data` and `mariadb_data`) mapped to `/home/rhiguita/data/wordpress` and `/home/rhiguita/data/mariadb` respectively, fulfilling the subject requirement while maintaining clean volume management.

---

## Instructions

### Documentation
- [User & Administrator Documentation (USER_DOC.md)](./USER_DOC.md) — Usage, credentials, stack lifecycle, and sanity checks.
- [Developer Documentation (DEV_DOC.md)](./DEV_DOC.md) — Technical setup, build pipeline, Docker commands, and volume architecture.

### Prerequisites
- Operating System: **Linux** (Debian/Ubuntu recommended)
- Installed dependencies: **Docker**, **Docker Compose**, and **GNU Make**.
- Add the target domain to your local `/etc/hosts` file:
  ```bash
  echo "127.0.0.1 rhiguita.42.fr" | sudo tee -a /etc/hosts
  ```

### Build & Run
All operations are wrapped in the root `Makefile`:

```bash
# Set up host directories, generate configuration secrets, build images, and start the containers
make

# Check status of the running containers
make status

# Stop containers without removing volumes
make stop

# Stop containers and destroy volumes/data
make clean

# Full reset (removes containers, networks, volumes, and built images)
make fclean
```

---

## Resources

### Reference Materials
- [Docker Documentation](https://docs.docker.com/) — Official reference for Dockerfiles and Compose files.
- [NGINX documentation](https://nginx.org/en/docs/) — Server blocks and SSL/TLS configurations.
- [MariaDB Knowledge Base](https://mariadb.com/kb/en/) — Client administration and server variables.
- [WordPress CLI (wp-cli)](https://wp-cli.org/) — Automated installation and user creation.

### AI Usage Disclosure
- **Tool used**: Google Gemini (via Antigravity programming assistant).
- **Assisted Tasks**:
  - Drafting system documentation structure (`README.md`, `USER_DOC.md`, `DEV_DOC.md`).
  - Designing the custom setup scripts for database initialization and `wp-cli` auto-install.
  - Translating system architecture schemas into Mermaid diagrams.
  - Validating standard configurations for PHP-FPM socket bindings and Nginx FastCGI parameters.
