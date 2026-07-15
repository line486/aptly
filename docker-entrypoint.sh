#!/bin/sh
set -eu

mkdir -p \
    /root/.gnupg \
    /root/.aptly/public \
    /var/log/nginx \
    /var/lib/nginx

chmod 700 /root/.gnupg
chmod 755 /root /root/.aptly /root/.aptly/public
find /root/.aptly/public -type d -exec chmod 755 {} + 2>/dev/null || true
find /root/.aptly/public -type f -exec chmod 644 {} + 2>/dev/null || true

nginx

exec "$@"