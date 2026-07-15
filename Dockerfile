# syntax=docker/dockerfile:1.7

FROM debian:bookworm-slim

ARG APTLY_VERSION

ENV DEBIAN_FRONTEND=noninteractive

SHELL ["/bin/bash", "-euxo", "pipefail", "-c"]

LABEL org.opencontainers.image.title="aptly" \
      org.opencontainers.image.description="aptly Debian repository management tool" \
      org.opencontainers.image.version="${APTLY_VERSION}" \
      org.opencontainers.image.source="https://github.com/aptly-dev/aptly" \
      org.opencontainers.image.licenses="MIT"

COPY docker-clean /etc/apt/apt.conf.d/docker-clean

ADD https://www.aptly.info/pubkey.txt /tmp/aptly-pubkey.txt

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update && \
    apt-get install -y ca-certificates gnupg && \
    rm -rf /var/lib/apt/lists/*

COPY aptly.list /etc/apt/sources.list.d/aptly.list

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    install -d -m0755 /etc/apt/keyrings && \
    gpg --dearmor < /tmp/aptly-pubkey.txt > /etc/apt/keyrings/aptly.gpg && \
    rm /tmp/aptly-pubkey.txt && \
    apt-get update && \
    apt-get install -y \
        "aptly-api${APTLY_VERSION:+=$APTLY_VERSION}" \
        bzip2 \
        curl \
        nginx \
        tini \
        xz-utils && \
    rm -rf /var/lib/apt/lists/*

COPY --link nginx.conf /etc/nginx/nginx.conf

COPY --chmod=755 docker-entrypoint.sh /usr/local/bin/

VOLUME ["/root/.gnupg"]
VOLUME ["/root/.aptly"]

EXPOSE 80

HEALTHCHECK \
    --interval=30s \
    --timeout=3s \
    --start-period=5s \
    --start-interval=5s \
    --retries=3 \
    CMD curl -fsS http://127.0.0.1/api/version || exit 1

STOPSIGNAL SIGTERM

ENTRYPOINT ["tini", "--", "docker-entrypoint.sh"]
CMD ["aptly", "api", "serve", "-listen=:8080"]