FROM debian:bookworm

RUN apt-get update && apt-get install -y --no-install-recommends \
        nginx \
        openssl \
    && rm -rf /var/lib/apt/lists/*

# Create directory for SSL certificates
RUN mkdir -p /etc/nginx/ssl

COPY conf/nginx.conf /etc/nginx/nginx.conf
COPY tools/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Only HTTPS is allowed — subject strictly forbids port 80
EXPOSE 443

ENTRYPOINT ["entrypoint.sh"]
