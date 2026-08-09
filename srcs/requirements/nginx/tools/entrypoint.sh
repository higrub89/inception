#!/bin/bash
set -euo pipefail

# ---------------------------------------------------------------------------
# NGINX Entrypoint — Inception (42 Madrid)
# ---------------------------------------------------------------------------
# 1. Generates a self-signed TLS certificate (TLSv1.2/TLSv1.3 compliant)
# 2. Injects the DOMAIN_NAME into nginx.conf
# 3. Starts NGINX in the foreground (PID 1)
# ---------------------------------------------------------------------------

DOMAIN="${DOMAIN_NAME:?DOMAIN_NAME not set}"
SSL_DIR="/etc/nginx/ssl"
CERT="${SSL_DIR}/nginx.crt"
KEY="${SSL_DIR}/nginx.key"

mkdir -p "${SSL_DIR}"

# --- Generate self-signed certificate if not already present ---
if [ ! -f "${CERT}" ] || [ ! -f "${KEY}" ]; then
    echo "[entrypoint] Generating self-signed TLS certificate for ${DOMAIN}..."
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout "${KEY}" \
        -out "${CERT}" \
        -subj "/C=ES/ST=Madrid/L=Madrid/O=42Madrid/OU=Student/CN=${DOMAIN}"
    echo "[entrypoint] Certificate generated."
fi

# --- Inject domain name into nginx configuration ---
echo "[entrypoint] Configuring server_name as '${DOMAIN}'..."
sed -i "s/__DOMAIN_NAME__/${DOMAIN}/g" /etc/nginx/nginx.conf

# --- Verify configuration syntax before starting ---
nginx -t

# --- Start NGINX in foreground (PID 1) ---
echo "[entrypoint] Starting NGINX..."
exec nginx -g "daemon off;"
