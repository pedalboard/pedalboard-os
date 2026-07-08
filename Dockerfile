FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential cmake git \
    libasound2-dev \
    sudo \
    jack-tools sox curl \
    && rm -rf /var/lib/apt/lists/*

# Create pedalboard user with sudo (needed for make install)
RUN useradd -m -G audio -s /bin/bash pedalboard \
    && echo "pedalboard ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/pedalboard

WORKDIR /opt/pedalboard-os
COPY . .

# Use our own Makefile for everything
RUN echo "jackd2 jackd/tweak_rt_limits boolean true" | debconf-set-selections
RUN make deps
RUN make install
RUN make curate

# Fix MOD UI data permissions for non-root user
RUN mkdir -p /opt/mod-ui/data && chown -R pedalboard:pedalboard /opt/mod-ui/data
RUN mkdir -p /home/pedalboard/.pedalboards && chown -R pedalboard:pedalboard /home/pedalboard/.pedalboards
COPY mod-favorites.json /opt/mod-ui/data/favorites.json
RUN chown pedalboard:pedalboard /opt/mod-ui/data/favorites.json

COPY docker-entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Generate test audio signal (1s 440Hz sine wave, 48kHz mono, 32-bit float)
RUN mkdir -p /opt/pedalboard-os/tests && \
    sox -n -r 48000 -c 1 -b 32 -e floating-point /opt/pedalboard-os/tests/sine-440hz.wav \
    synth 1 sine 440

COPY tests/ /opt/pedalboard-os/tests/
RUN chmod +x /opt/pedalboard-os/tests/*.sh 2>/dev/null || true

USER pedalboard
EXPOSE 8080 8888

ENTRYPOINT ["/entrypoint.sh"]
