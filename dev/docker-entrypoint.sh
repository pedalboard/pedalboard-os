#!/bin/bash
set -e

echo "Starting pedalboard dev environment..."

# Fix volume permissions (Docker volumes are created as root)
sudo chown -R pedalboard:pedalboard /home/pedalboard/.pedalboards 2>/dev/null || true

# Install favorites if empty
if [ ! -f /opt/mod-ui/data/favorites.json ] || [ "$(cat /opt/mod-ui/data/favorites.json)" = "[]" ]; then
    cp /opt/pedalboard-os/mod-favorites.json /opt/mod-ui/data/favorites.json
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

MODE="${MODE:-dev}"

if [ "$MODE" = "test" ]; then
    # ─── Test mode: bridge + MIDI FIFO for e2e tests ───
    echo "Mode: test"
    MIDI_FIFO="/tmp/midi-fifo"
    mkfifo "$MIDI_FIFO"
    exec 7<>"$MIDI_FIFO"

    /usr/local/bin/pedalboard-bridge -port "$MIDI_FIFO" -addr :8080 \
        -audio /opt/pedalboard-os/tests/audio-patches-test.json -modhost localhost:5555 &

    # Wait for bridge to be ready
    for i in $(seq 1 40); do
        response=$(curl -sf http://localhost:8080/mode 2>/dev/null || true)
        if [ "$response" = "live" ]; then
            break
        fi
        sleep 1
    done

    if [ $# -gt 0 ]; then
        exec "$@"
    else
        wait
    fi
else
    # ─── Dev mode: bridge + simulator + MOD UI available ───
    MIDI_FIFO="/tmp/midi-fifo"
    mkfifo "$MIDI_FIFO"
    exec 7<>"$MIDI_FIFO"

    # Start bridge (connects to mod-host, reads MIDI from FIFO)
    /usr/local/bin/pedalboard-bridge -port "$MIDI_FIFO" -addr :8080 \
        -audio /etc/pedalboard/audio-patches.json -modhost localhost:5555 &
    sleep 2

    # Start simulator if binary is available
    SIM_BIN=$(command -v pedalboard-sim 2>/dev/null || echo "/opt/sim-bin/pedalboard-sim")
    if [ -x "$SIM_BIN" ]; then
        CONFIG_ARG=""
        if [ -f /opt/sim-bin/config.bin ]; then
            CONFIG_ARG="-c /opt/sim-bin/config.bin"
        elif [ -f /opt/pedalboard-os/config.bin ]; then
            CONFIG_ARG="-c /opt/pedalboard-os/config.bin"
        fi
        "$SIM_BIN" --raw "$MIDI_FIFO" --web 0.0.0.0:3001 $CONFIG_ARG &
    fi

    # Start MOD UI (bridge switches to design mode via POST /mode?set=design)
    cd /opt/mod-ui
    export MOD_DEV_ENVIRONMENT=0
    export MOD_DEV_HMI=1
    export MOD_DEV_HOST=0
    export MOD_HOST_PORT=5555
    export MOD_DATA_DIR=/opt/mod-ui/data
    python3 server.py &

    echo ""
    echo "Ready:"
    echo "  Bridge:    http://localhost:8080"
    echo "  Simulator: http://localhost:3001"
    echo "  MOD UI:    http://localhost:8888"
    echo ""
    echo "Switch modes via bridge: POST http://localhost:8080/mode?set=live|design"
    echo ""
    wait
fi
