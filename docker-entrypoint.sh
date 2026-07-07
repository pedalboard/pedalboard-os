#!/bin/bash
set -e

echo "Starting pedalboard test environment..."

# Install favorites if empty
if [ ! -f /opt/mod-ui/data/favorites.json ] || [ "$(cat /opt/mod-ui/data/favorites.json)" = "[]" ]; then
    cp /opt/pedalboard-os/mod-favorites.json /opt/mod-ui/data/favorites.json 2>/dev/null || true
fi

# Start JACK with dummy driver (no real audio hardware)
jackd -d dummy -r 48000 -p 256 &
sleep 1

# Set port aliases (same as pedalboard-jack.service)
jack_alias system:capture_1 "IN L" 2>/dev/null || true
jack_alias system:capture_2 "IN R" 2>/dev/null || true
jack_alias system:playback_1 "OUT L" 2>/dev/null || true
jack_alias system:playback_2 "OUT R" 2>/dev/null || true

# Start mod-host with feedback port
mod-host -n -p 5555 -f 5556 &
sleep 1

# Start MOD UI or bridge depending on MODE env var
MODE="${MODE:-design}"

if [ "$MODE" = "design" ]; then
    echo "Mode: design (MOD UI on http://localhost:8888)"
    cd /opt/mod-ui
    export MOD_DEV_ENVIRONMENT=0
    export MOD_DEV_HMI=1
    export MOD_DEV_HOST=0
    export MOD_HOST_PORT=5555
    export MOD_DATA_DIR=/opt/mod-ui/data
    exec python3 server.py
else
    echo "Mode: live (bridge on http://localhost:8080)"
    echo "Waiting for bridge binary at /usr/local/bin/pedalboard-bridge..."
    exec /usr/local/bin/pedalboard-bridge -port dummy -addr :8080 -audio /etc/pedalboard/audio-patches.json -modhost localhost:5555
fi
