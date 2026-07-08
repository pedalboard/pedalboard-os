# Pedalboard OS

System configuration for the Open Pedalboard audio+MIDI platform running on Raspberry Pi CM5.

**Stack:** Debian Bookworm + JACK + AIDA-X + mod-host + pedalboard-bridge

## Prerequisites

- Raspberry Pi CM5 with Debian Bookworm
- Pedalboard soundcard (PCM1863 ADC + PCM5242 DAC) connected via I2S
- Pedalboard MIDI controller (RP2040) connected via USB

## Install

```bash
git clone https://github.com/pedalboard/pedalboard-os.git
cd pedalboard-os
make install
sudo reboot
```

## Services

| Service | Description |
|---------|-------------|
| `pedalboard-jack` | JACK audio server (hw:3, 48kHz, 64 frames, 2ch) |
| `pedalboard-bridge` | WebSocket↔MIDI bridge + mod-host audio switching |

## Configuration

```
/etc/pedalboard/
├── audio-patches.json    # Audio plugin chain per preset
└── models/               # AIDA-X model state directories
    └── default/
        ├── state.ttl
        └── model.aidax
```

## Local Development

Run the full audio stack locally in Docker (no CM5 or soundcard required):

### Design mode — build plugin chains in MOD UI

```bash
make dev
```

Opens MOD UI at http://localhost:8888. Uses a JACK dummy driver for audio routing without real hardware.

### Live mode — test with the bridge

```bash
make dev-live
```

Runs pedalboard-bridge at http://localhost:8080. To test with a local bridge build, uncomment the volume mount in `docker-compose.yml`:

```yaml
volumes:
  - ../pedalboard-bridge/pedalboard-bridge:/usr/local/bin/pedalboard-bridge
```

### Testing against the dev environment

```bash
# Verify MOD UI is running (design mode)
curl -s http://localhost:8888 | head

# Test with pedalboard-cli (live mode)
cd ../pedalboard-cli
cargo run -- monitor
cargo run -- upload <preset.yaml>
```

### Stop

```bash
make dev-down
```

## Manual Testing (on CM5)

```bash
# Check services
systemctl status pedalboard-jack pedalboard-bridge

# Test audio output
speaker-test -D hw:3 -c 2 -t sine -f 440 -s 2

# Direct loopback (guitar test)
jack_connect system:capture_2 system:playback_2

# Check JACK
jack_lsp -c
```

## License

[GPL-3.0](LICENSE)
