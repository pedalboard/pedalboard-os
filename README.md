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

### Sim mode — full stack with the virtual pedalboard

```bash
make dev-sim
```

Runs the complete audio chain with the pedalboard simulator:

| Service | URL | Description |
|---------|-----|-------------|
| Bridge | http://localhost:8080 | Receives MIDI, switches audio patches |
| Simulator | http://localhost:3001 | Virtual pedalboard (buttons, encoders, LEDs) |

The simulator sends raw MIDI through a FIFO to the bridge — identical to how the real RP2040 controller communicates via `/dev/snd/midiC*D*`. Press buttons in the web UI to trigger preset changes.

First run builds the simulator in a Rust container (cached after that).

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

### End-to-end tests — verify audio routing

```bash
make e2e
```

Runs automated tests inside Docker that verify the bridge correctly switches audio plugin chains via mod-host when it receives MIDI Program Change messages. The test uses:

- **JACK dummy driver** for audio port topology (no real audio hardware)
- **MIDI FIFO** simulating the raw ALSA device (`/dev/snd/midiC99D0`) — the test writes Program Change bytes directly to the FIFO
- **jack-play / jack-record** + **sox** for audio signal injection and verification

Test cases:
1. Bridge starts in live mode
2. Initial patch (preset 0) loads on startup
3. Preset switch changes JACK connections
4. Audio signal passes through plugin chain
5. Different presets produce different configurations
6. Invalid preset number doesn't crash the bridge

When the MIDI simulator is ready, it can replace the FIFO by connecting as the actual USB MIDI device (or by writing to the same FIFO path for integration testing).

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
