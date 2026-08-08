#!/bin/bash
set -euo pipefail

# ---------------------------------------------------------------------------
# WordPress + PHP-FPM Entrypoint — Inception (42 Madrid)
# ---------------------------------------------------------------------------
# 1. Waits for MariaDB to be reachable
# 2. Downloads and configures WordPress via WP-CLI
# 3. Creates the admin user and an additional subscriber user
# 4. Starts PHP-FPM in the foreground (PID 1)
# ---------------------------------------------------------------------------

# --- Read secrets from mounted files ---
DB_PASSWORD="$(cat /run/secrets/db_password)"
WP_ADMIN_PASSWORD="$(cat /run/secrets/wp_admin_password)"

# --- Environment variables (from .env via docker-compose) ---
DB_NAME="${MYSQL_DATABASE:?MYSQL_DATABASE not set}"
DB_USER="${MYSQL_USER:?MYSQL_USER not set}"
DOMAIN="${DOMAIN_NAME:?DOMAIN_NAME not set}"
TITLE="${WP_TITLE:?WP_TITLE not set}"
ADMIN="${WP_ADMIN_USER:?WP_ADMIN_USER not set}"
ADMIN_EMAIL="${WP_ADMIN_EMAIL:?WP_ADMIN_EMAIL not set}"
WP_SUBSCRIBER="${WP_USER:?WP_USER not set}"
WP_SUBSCRIBER_EMAIL="${WP_EMAIL:?WP_EMAIL not set}"

WP_PATH="/var/www/html"

# --- Wait for MariaDB to be ready ---
echo "[entrypoint] Waiting for MariaDB at mariadb:3306..."
until mariadb-admin ping -h mariadb -u "${DB_USER}" -p"${DB_PASSWORD}" --silent 2>/dev/null; do
    sleep 1
done
echo "[entrypoint] MariaDB is up."

# --- Install WordPress if not already configured ---
if [ ! -f "${WP_PATH}/wp-config.php" ]; then
    echo "[entrypoint] Downloading WordPress core..."
    wp core download --path="${WP_PATH}" --allow-root

    echo "[entrypoint] Creating wp-config.php..."
    wp config create \
        --dbname="${DB_NAME}" \
        --dbuser="${DB_USER}" \
        --dbpass="${DB_PASSWORD}" \
        --dbhost="mariadb:3306" \
        --path="${WP_PATH}" \
        --allow-root

    echo "[entrypoint] Installing WordPress..."
    wp core install \
        --url="https://${DOMAIN}" \
        --title="${TITLE}" \
        --admin_user="${ADMIN}" \
        --admin_password="${WP_ADMIN_PASSWORD}" \
        --admin_email="${ADMIN_EMAIL}" \
        --skip-email \
        --path="${WP_PATH}" \
        --allow-root

    echo "[entrypoint] Creating subscriber user '${WP_SUBSCRIBER}'..."
    wp user create "${WP_SUBSCRIBER}" "${WP_SUBSCRIBER_EMAIL}" \
        --role=subscriber \
        --user_pass="${DB_PASSWORD}" \
        --path="${WP_PATH}" \
        --allow-root

    echo "[entrypoint] WordPress installation complete."
else
    echo "[entrypoint] WordPress already configured, skipping install."
fi

# --- Fix ownership ---
chown -R www-data:www-data "${WP_PATH}"

# --- Start PHP-FPM in foreground (PID 1) ---
echo "[entrypoint] Starting PHP-FPM 8.2 in foreground..."
exec php-fpm8.2 -F
