#!/bin/bash
set -euo pipefail

# ---------------------------------------------------------------------------
# MariaDB Entrypoint — Inception (42 Madrid)
# ---------------------------------------------------------------------------
# 1. Reads credentials from Docker Secrets (/run/secrets/)
# 2. Initializes the database if it doesn't exist
# 3. Creates the project database, user, and grants privileges
# 4. Starts MariaDB in the foreground (PID 1)
# ---------------------------------------------------------------------------

# --- Read secrets from mounted files ---
DB_PASSWORD="$(cat /run/secrets/db_password)"
DB_ROOT_PASSWORD="$(cat /run/secrets/db_root_password)"

# --- Environment variables (from .env via docker-compose) ---
DB_NAME="${MYSQL_DATABASE:?MYSQL_DATABASE not set}"
DB_USER="${MYSQL_USER:?MYSQL_USER not set}"

# --- Ensure log directory exists ---
mkdir -p /var/log/mysql
chown mysql:mysql /var/log/mysql

# --- Initialize database if not already done ---
if [ ! -d "/var/lib/mysql/${DB_NAME}" ]; then
    echo "[entrypoint] Initializing MariaDB data directory..."
    mariadb-install-db --user=mysql --datadir=/var/lib/mysql > /dev/null 2>&1

    echo "[entrypoint] Starting temporary MariaDB instance for setup..."
    mariadbd --user=mysql --datadir=/var/lib/mysql --skip-networking &
    TEMP_PID=$!

    # Wait until MariaDB is ready to accept connections
    until mariadb-admin ping --silent 2>/dev/null; do
        sleep 1
    done

    echo "[entrypoint] Creating database '${DB_NAME}' and user '${DB_USER}'..."
    mariadb -u root <<-EOF
		CREATE DATABASE IF NOT EXISTS \`${DB_NAME}\`;
		CREATE USER IF NOT EXISTS '${DB_USER}'@'%' IDENTIFIED BY '${DB_PASSWORD}';
		GRANT ALL PRIVILEGES ON \`${DB_NAME}\`.* TO '${DB_USER}'@'%';
		ALTER USER 'root'@'localhost' IDENTIFIED BY '${DB_ROOT_PASSWORD}';
		FLUSH PRIVILEGES;
	EOF

    echo "[entrypoint] Shutting down temporary instance..."
    mariadb-admin -u root -p"${DB_ROOT_PASSWORD}" shutdown
    wait "${TEMP_PID}"

    echo "[entrypoint] MariaDB initialization complete."
fi

# --- Start MariaDB in foreground (PID 1) ---
echo "[entrypoint] Starting MariaDB in foreground..."
exec mariadbd --user=mysql --datadir=/var/lib/mysql
