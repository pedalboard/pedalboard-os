FROM debian:bullseye-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential cmake git \
    libasound2-dev \
    sudo \
    && rm -rf /var/lib/apt/lists/*

# Create pedalboard user with sudo (needed for make install)
RUN useradd -m -G audio -s /bin/bash pedalboard \
    && echo "pedalboard ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/pedalboard

WORKDIR /opt/pedalboard-os
COPY . .

# Use our own Makefile for everything
RUN make deps
RUN make install

# Fix MOD UI data permissions for non-root user
RUN mkdir -p /opt/mod-ui/data && chown -R pedalboard:pedalboard /opt/mod-ui/data

COPY docker-entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

USER pedalboard
EXPOSE 8080 8888

ENTRYPOINT ["/entrypoint.sh"]
